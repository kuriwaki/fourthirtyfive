// # Written by Codex

(function () {
  "use strict";

  function loadingMessage(className, parent) {
    var message = document.createElement("p");
    message.className = className;
    message.setAttribute("role", "status");
    message.textContent = "Loading interactive map…";
    parent.appendChild(message);
    return message;
  }

  function initializeWidgetFallback() {
    var root = document.documentElement;
    var fallback = document.querySelector(".cd-map-fallback");
    var widget = document.querySelector(".mapboxgl.html-widget");
    if (!fallback) return;
    if (!widget) {
      root.dataset.cdMapState = "fallback";
      return;
    }
    var loading = loadingMessage("cd-map-loading", fallback.parentNode);

    var map;
    var poll;
    var timeout;
    var hasLoaded = false;
    var contextLost = false;
    var authFailed = false;
    var observer;

    function setState(state) {
      if (root.dataset.cdMapState === state) return;
      root.dataset.cdMapState = state;
      // The homepage also needs a fallback when this entire iframe fails.
      if (window.parent !== window && window.location.origin !== "null") {
        window.parent.postMessage({ type: "cd-map-state", state: state }, window.location.origin);
      }
    }

    function showFallback() {
      setState("fallback");
      loading.hidden = true;
      fallback.setAttribute("role", "status");
    }

    function showLiveMap() {
      hasLoaded = true;
      clearTimeout(timeout);
      setState("ready");
      loading.hidden = true;
      fallback.removeAttribute("role");
    }

    function hasBasemapFeatures() {
      // These examples use Mapbox Streets. Local district/city GeoJSON can
      // finish loading even when every basemap tile download has failed.
      var style = map.getStyle();
      var basemapLayers = style.layers.filter(function (layer) {
        var source = style.sources[layer.source];
        return source && source.type === "vector";
      }).map(function (layer) { return layer.id; });
      if (!basemapLayers.length) return false;
      var canvas = map.getCanvas();
      return map.queryRenderedFeatures(
        [[0, 0], [canvas.clientWidth, canvas.clientHeight]],
        { layers: basemapLayers }
      ).length > 0;
    }

    function checkMapReady() {
      if (map && !contextLost && !authFailed && map.loaded() &&
          map.isStyleLoaded() && hasBasemapFeatures()) {
        showLiveMap();
      }
    }

    function attachMap() {
      // mapgl exposes the real Mapbox instance on its widget element.
      if (map || !widget.map) return;
      map = widget.map;
      clearInterval(poll);
      observer.disconnect();
      map.on("load", checkMapReady);
      map.on("idle", checkMapReady);
      map.on("webglcontextlost", function () {
        contextLost = true;
        showFallback();
      });
      map.on("webglcontextrestored", function () {
        contextLost = false;
        checkMapReady();
      });
      map.on("error", function (event) {
        var error = event.error || {};
        // A recoverable tile or telemetry error should not hide a working map.
        var telemetry = String(error.url || "").indexOf("events.mapbox.com") !== -1;
        if (!hasLoaded && !telemetry && (error.status === 401 || error.status === 403)) {
          authFailed = true;
          showFallback();
        }
      });
      checkMapReady();
    }

    // A stalled download, absent library, or failed WebGL constructor may never
    // produce a Mapbox error event. Continue watching for a late recovery.
    setState("loading");
    observer = new MutationObserver(attachMap);
    observer.observe(widget, { childList: true, subtree: true });
    timeout = setTimeout(function () {
      showFallback();
      clearInterval(poll);
    }, 20000);
    poll = setInterval(attachMap, 100);
    attachMap();
    window.addEventListener("pagehide", function (event) {
      if (event.persisted) return;
      clearInterval(poll);
      clearTimeout(timeout);
      observer.disconnect();
    }, { once: true });
  }

  function initializeFrameFallback(frame) {
    var iframe = frame.querySelector(".cd-map-iframe");
    var fallback = frame.querySelector(".cd-map-outer-fallback");
    if (!iframe || !fallback) return;
    var loading = loadingMessage("cd-map-frame-loading", frame);
    var timeout;
    var started = false;

    function setState(state) {
      frame.dataset.cdMapState = state;
      loading.hidden = state !== "loading";
      fallback.setAttribute("aria-hidden", state === "fallback" ? "false" : "true");
      iframe.setAttribute("aria-hidden", state === "ready" ? "false" : "true");
      if (state !== "loading") clearTimeout(timeout);
    }

    function readChildState() {
      try {
        var state = iframe.contentDocument.documentElement.dataset.cdMapState;
        if (state === "ready" || state === "fallback") setState(state);
      } catch (error) {
        // A missing or inaccessible document is covered by the watchdog.
      }
    }

    function startWatchdog() {
      if (started) return;
      started = true;
      timeout = setTimeout(function () { setState("fallback"); }, 25000);
      readChildState();
    }

    setState("loading");
    iframe.addEventListener("load", function () {
      startWatchdog();
      readChildState();
    });
    iframe.addEventListener("error", function () { setState("fallback"); });
    window.addEventListener("message", function (event) {
      if (event.origin !== window.location.origin || event.source !== iframe.contentWindow) return;
      var message = event.data;
      if (!message || message.type !== "cd-map-state") return;
      if (message.state === "ready" || message.state === "fallback") setState(message.state);
    });

    // Native lazy iframe loading varies by browser. Do not time out an unseen
    // map simply because its document has not started loading yet.
    var intersection;
    if ("IntersectionObserver" in window) {
      intersection = new IntersectionObserver(function (entries) {
        if (entries.some(function (entry) { return entry.isIntersecting; })) {
          startWatchdog();
          intersection.disconnect();
        }
      }, { rootMargin: "300px 0px" });
      intersection.observe(frame);
    } else {
      startWatchdog();
    }
    readChildState();
    window.addEventListener("pagehide", function (event) {
      if (event.persisted) return;
      clearTimeout(timeout);
      if (intersection) intersection.disconnect();
    }, { once: true });
  }

  function initializeFallbacks() {
    initializeWidgetFallback();
    document.querySelectorAll(".cd-map-frame").forEach(initializeFrameFallback);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initializeFallbacks, { once: true });
  } else {
    initializeFallbacks();
  }
}());
