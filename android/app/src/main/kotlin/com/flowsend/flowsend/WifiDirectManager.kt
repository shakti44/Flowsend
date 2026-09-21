package com.flowsend.flowsend

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pDeviceList
import android.net.wifi.p2p.WifiP2pInfo
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * FlowSend Smart Connection — Wi-Fi Direct (P2P) support.
 *
 * Used only when the two devices are NOT on the same Wi-Fi network. Same-Wi-Fi
 * transfers never touch this class — they keep using the existing LAN/TCP path.
 */
class WifiDirectManager(private val context: Context, private val messenger: BinaryMessenger) {

    private val manager: WifiP2pManager? =
        context.getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
    private var channel: WifiP2pManager.Channel? = null
    private var receiver: BroadcastReceiver? = null
    private var peersSink: EventChannel.EventSink? = null
    private var statusSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private val intentFilter = IntentFilter().apply {
        addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
        addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
        addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
        addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
    }

    init {
        if (manager != null) {
            channel = manager.initialize(context, Looper.getMainLooper(), null)
        }
    }

    fun attach() {
        MethodChannel(messenger, "flowsend/wifi_direct").setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> result.success(manager != null)
                "startDiscovery" -> startDiscovery(result)
                "stopDiscovery" -> stopDiscovery(result)
                "connect" -> connect(call.argument<String>("address"), result)
                "cancelConnect" -> cancelConnect(result)
                "disconnect" -> disconnect(result)
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "flowsend/wifi_direct/peers").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    peersSink = events
                }

                override fun onCancel(arguments: Any?) {
                    peersSink = null
                }
            },
        )

        EventChannel(messenger, "flowsend/wifi_direct/status").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    statusSink = events
                }

                override fun onCancel(arguments: Any?) {
                    statusSink = null
                }
            },
        )
    }

    fun onResume() {
        if (manager == null || channel == null) return
        receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                handleP2pIntent(intent)
            }
        }
        context.registerReceiver(receiver, intentFilter)
    }

    fun onPause() {
        receiver?.let { context.unregisterReceiver(it) }
        receiver = null
    }

    private fun handleP2pIntent(intent: Intent) {
        when (intent.action) {
            WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> requestPeers()
            WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> requestConnectionInfo()
            WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                val enabled = intent.getIntExtra(
                    WifiP2pManager.EXTRA_WIFI_STATE,
                    WifiP2pManager.WIFI_P2P_STATE_DISABLED,
                ) == WifiP2pManager.WIFI_P2P_STATE_ENABLED
                mainHandler.post {
                    statusSink?.success(mapOf("event" to "radioState", "enabled" to enabled))
                }
            }
        }
    }

    private fun startDiscovery(result: MethodChannel.Result) {
        val mgr = manager
        val ch = channel
        if (mgr == null || ch == null) {
            result.error("UNSUPPORTED", "Wi-Fi Direct is not supported on this device", null)
            return
        }
        mgr.discoverPeers(ch, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                result.success(true)
            }

            override fun onFailure(reasonCode: Int) {
                result.error("DISCOVERY_FAILED", "reason=$reasonCode", null)
            }
        })
    }

    private fun stopDiscovery(result: MethodChannel.Result) {
        val mgr = manager
        val ch = channel
        if (mgr == null || ch == null) {
            result.success(false)
            return
        }
        mgr.stopPeerDiscovery(ch, object : WifiP2pManager.ActionListener {
            override fun onSuccess() = result.success(true)
            override fun onFailure(reasonCode: Int) = result.success(false)
        })
    }

    private fun requestPeers() {
        val mgr = manager
        val ch = channel ?: return
        mgr?.requestPeers(ch) { peers: WifiP2pDeviceList ->
            val list = peers.deviceList.map { device: WifiP2pDevice ->
                mapOf(
                    "name" to device.deviceName,
                    "address" to device.deviceAddress,
                    "status" to device.status,
                )
            }
            mainHandler.post { peersSink?.success(list) }
        }
    }

    private fun requestConnectionInfo() {
        val mgr = manager
        val ch = channel ?: return
        mgr?.requestConnectionInfo(ch) { info: WifiP2pInfo ->
            mainHandler.post {
                statusSink?.success(
                    mapOf(
                        "event" to "connectionInfo",
                        "connected" to info.groupFormed,
                        "isGroupOwner" to info.isGroupOwner,
                        "groupOwnerAddress" to info.groupOwnerAddress?.hostAddress,
                    ),
                )
            }
        }
    }

    private fun connect(address: String?, result: MethodChannel.Result) {
        val mgr = manager
        val ch = channel
        if (mgr == null || ch == null) {
            result.error("UNSUPPORTED", "Wi-Fi Direct is not supported on this device", null)
            return
        }
        if (address == null) {
            result.error("INVALID_ADDRESS", "Peer device address is required", null)
            return
        }
        val config = WifiP2pConfig().apply {
            deviceAddress = address
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                wps.setup = android.net.wifi.WpsInfo.PBC
            }
        }
        mgr.connect(ch, config, object : WifiP2pManager.ActionListener {
            override fun onSuccess() = result.success(true)
            override fun onFailure(reasonCode: Int) {
                // ERROR=0, P2P_UNSUPPORTED=1, BUSY=2 per WifiP2pManager constants.
                result.error("CONNECT_FAILED", "reason=$reasonCode", null)
            }
        })
    }

    private fun cancelConnect(result: MethodChannel.Result) {
        val mgr = manager
        val ch = channel
        if (mgr == null || ch == null) {
            result.success(false)
            return
        }
        mgr.cancelConnect(ch, object : WifiP2pManager.ActionListener {
            override fun onSuccess() = result.success(true)
            override fun onFailure(reasonCode: Int) = result.success(false)
        })
    }

    private fun disconnect(result: MethodChannel.Result) {
        val mgr = manager
        val ch = channel
        if (mgr == null || ch == null) {
            result.success(false)
            return
        }
        // removeGroup tears down the temporary P2P group so the device
        // returns to its normal Wi-Fi state — nothing is left behind.
        mgr.removeGroup(ch, object : WifiP2pManager.ActionListener {
            override fun onSuccess() = result.success(true)
            override fun onFailure(reasonCode: Int) = result.success(false)
        })
    }
}
