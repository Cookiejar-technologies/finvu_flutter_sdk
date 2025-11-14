package com.finvu.android.events

import android.util.Log
import com.finvu.android.publicInterface.FinvuEvent
import com.finvu.android.publicInterface.FinvuEventListener
import com.finvu.android.utils.FinvuErrorMessages
import kotlinx.coroutines.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Thread-safe, optimized event tracker with lazy initialization
 * - Only initializes when first listener is added
 * - Resets all data when last listener is removed
 * - No memory/thread overhead until actively used
 */
class FinvuEventTracker private constructor() {
    companion object {
        private const val TAG = "FinvuEventTracker"
        const val SDK_VERSION = "1.0.8"
        
        @Volatile
        private var INSTANCE: FinvuEventTracker? = null
        
        val shared: FinvuEventTracker
            get() = INSTANCE ?: synchronized(this) {
                INSTANCE ?: FinvuEventTracker().also { INSTANCE = it }
            }
    }
    
    // Thread-safe collections
    private val eventListeners = CopyOnWriteArrayList<FinvuEventListener>()
    private val customEvents = ConcurrentHashMap<String, EventDefinition>()
    private val eventAliases = ConcurrentHashMap<String, String>()
    
    // Atomic flags
    // Events are disabled by default - must call setEventsEnabled(true) to track events
    private val eventsEnabled = AtomicBoolean(false)
    private val isInitialized = AtomicBoolean(false)
    
    // Lazy-initialized coroutine scopes (only created when needed)
    private var eventProcessingScope: CoroutineScope? = null
    private var notificationScope: CoroutineScope? = null
    
    /**
     * Initialize coroutine scopes (called lazily on first listener)
     */
    private fun initializeIfNeeded() {
        if (isInitialized.compareAndSet(false, true)) {
            eventProcessingScope = CoroutineScope(
                SupervisorJob() + Dispatchers.Default + CoroutineName("FinvuEventTracker")
            )
            notificationScope = CoroutineScope(
                SupervisorJob() + Dispatchers.Main.immediate + CoroutineName("FinvuEventNotification")
            )
            Log.d(TAG, FinvuErrorMessages.EVENT_TRACKER_INITIALIZED)
        }
    }
    
    /**
     * Cleanup and reset (called when last listener removed)
     */
    private fun cleanup() {
        if (isInitialized.compareAndSet(true, false)) {
            eventProcessingScope?.cancel()
            notificationScope?.cancel()
            eventProcessingScope = null
            notificationScope = null
            
            // Reset all event definitions
            FinvuEventDefinitions.resetAll()
            customEvents.clear()
            eventAliases.clear()
            
            Log.d(TAG, FinvuErrorMessages.EVENT_TRACKER_CLEANED_UP)
        }
    }
    
    /**
     * Enable/disable event tracking (thread-safe)
     * 
     * Events are disabled by default. You must call setEventsEnabled(true) 
     * to start tracking events, even if listeners are added.
     * 
     * @param enabled True to enable event tracking, false to disable
     */
    fun setEventsEnabled(enabled: Boolean) {
        eventsEnabled.set(enabled)
        Log.d(TAG, if (enabled) FinvuErrorMessages.EVENT_TRACKING_ENABLED else FinvuErrorMessages.EVENT_TRACKING_DISABLED)
    }
    
    /**
     * Add event listener (thread-safe)
     * Initializes tracker on first listener
     */
    fun addEventListener(listener: FinvuEventListener) {
        if (!eventListeners.contains(listener)) {
            eventListeners.add(listener)
            initializeIfNeeded()
            Log.d(TAG, String.format(FinvuErrorMessages.EVENT_LISTENER_ADDED, eventListeners.size))
        }
    }
    
    /**
     * Remove event listener (thread-safe)
     * Cleans up and resets when last listener removed
     */
    fun removeEventListener(listener: FinvuEventListener) {
        if (eventListeners.remove(listener)) {
            Log.d(TAG, String.format(FinvuErrorMessages.EVENT_LISTENER_REMOVED, eventListeners.size))
            
            // If no more listeners, cleanup and reset
            if (eventListeners.isEmpty()) {
                cleanup()
            }
        }
    }
    
    /**
     * Track event - optimized for performance
     * - Fast path if events disabled or no listeners
     * - Minimal allocations
     * - Single coroutine launch for all listeners
     */
    fun track(eventName: String, params: Map<String, Any?> = emptyMap()) {
        // Fast path: early return if disabled or no listeners (no allocations)
        if (!eventsEnabled.get() || !isInitialized.get() || eventListeners.isEmpty()) {
            return
        }
        
        // Process event asynchronously to avoid blocking caller
        eventProcessingScope?.launch {
            try {
                // Find event definition (fast lookup)
                val eventDef = FinvuEventDefinitions.getAllDefinitions()[eventName] 
                    ?: customEvents[eventName]
                
                if (eventDef == null) {
                    Log.w(TAG, String.format(FinvuErrorMessages.UNKNOWN_EVENT, eventName))
                    return@launch
                }
                
                // Update count atomically
                eventDef.count++
                
                // Build event object (minimal allocations)
                val eventObject = buildEventObject(eventName, eventDef, params)
                
                // Notify all listeners in single coroutine (efficient)
                notifyListeners(eventObject)
                
            } catch (e: Exception) {
                Log.e(TAG, String.format(FinvuErrorMessages.ERROR_TRACKING_EVENT, eventName), e)
            }
        }
    }
    
    /**
     * Build event object - extracted for testability
     */
    private fun buildEventObject(
        eventName: String,
        eventDef: EventDefinition,
        params: Map<String, Any?>
    ): FinvuEvent {
        val finalParams = mutableMapOf<String, Any?>().apply {
            // Add standard properties
            put("count", eventDef.count)
            eventDef.stage?.let { put("stage", it) }
            eventDef.fipId?.let { put("fipId", it) }
            if (eventDef.fips.isNotEmpty()) put("fips", eventDef.fips.toList())
            if (eventDef.fiTypes.isNotEmpty()) put("fiTypes", eventDef.fiTypes.toList())
            // Merge custom params (override standard if conflict)
            putAll(params)
        }
        
        return FinvuEvent(
            eventName = eventAliases[eventName] ?: eventName,
            eventCategory = eventDef.category,
            timestamp = java.time.Instant.now().toString(),
            aaSdkVersion = SDK_VERSION,
            params = finalParams
        )
    }
    
    /**
     * Notify all listeners efficiently
     */
    private fun notifyListeners(event: FinvuEvent) {
        // Fast path: no listeners
        if (eventListeners.isEmpty()) return
        
        // Launch single coroutine for all notifications
        notificationScope?.launch {
            eventListeners.forEach { listener ->
                try {
                    listener.onEvent(event)
                } catch (e: Exception) {
                    Log.e(TAG, String.format(FinvuErrorMessages.ERROR_NOTIFYING_LISTENER, listener::class.simpleName), e)
                }
            }
        }
    }
    
    /**
     * Register custom events (thread-safe)
     */
    fun registerCustomEvents(events: Map<String, EventDefinition>) {
        events.forEach { (eventName, definition) ->
            if (FinvuEventDefinitions.getAllDefinitions().containsKey(eventName)) {
                Log.e(TAG, String.format(FinvuErrorMessages.EVENT_NAME_ALREADY_EXISTS, eventName))
                return@forEach
            }
            customEvents[eventName] = definition
        }
    }
    
    /**
     * Register event aliases (thread-safe)
     */
    fun registerAliases(aliases: Map<String, String>) {
        aliases.forEach { (eventName, alias) ->
            if (eventAliases.values.contains(alias)) {
                Log.e(TAG, String.format(FinvuErrorMessages.ALIAS_ALREADY_IN_USE, alias))
                return@forEach
            }
            if (!FinvuEventDefinitions.getAllDefinitions().containsKey(eventName)) {
                Log.e(TAG, String.format(FinvuErrorMessages.CANNOT_CREATE_ALIAS, eventName))
                return@forEach
            }
            eventAliases[eventName] = alias
        }
    }
    
    /**
     * Check if tracker is initialized (for testing)
     */
    fun isInitialized(): Boolean = isInitialized.get()
}

