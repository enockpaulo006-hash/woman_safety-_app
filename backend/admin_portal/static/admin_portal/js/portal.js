document.documentElement.classList.add("portal-ready");

const printBriefButton = document.querySelector("[data-print-brief]");
const sidebarToggleButton = document.querySelector("[data-sidebar-toggle]");

if (sidebarToggleButton) {
  const storageKey = "portalSidebarCollapsed";
  let savedPreference = null;

  try {
    savedPreference = window.localStorage.getItem(storageKey);
  } catch {
    savedPreference = null;
  }

  const defaultCollapsed = false;
  const setSidebarCollapsed = (isCollapsed) => {
    document.body.classList.toggle("is-sidebar-collapsed", isCollapsed);
    sidebarToggleButton.setAttribute("aria-expanded", String(!isCollapsed));
    sidebarToggleButton.textContent = isCollapsed ? "Show menu" : "Hide menu";
  };

  setSidebarCollapsed(
    savedPreference === null ? defaultCollapsed : savedPreference === "true",
  );

  sidebarToggleButton.addEventListener("click", () => {
    const isCollapsed = !document.body.classList.contains("is-sidebar-collapsed");
    setSidebarCollapsed(isCollapsed);
    try {
      window.localStorage.setItem(storageKey, String(isCollapsed));
    } catch {
      // Ignore storage failures; the toggle still works for the current page.
    }
  });
}

if (printBriefButton) {
  printBriefButton.addEventListener("click", () => window.print());
}

const escapeHtml = (value) =>
  String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");

const hotspotDataNode = document.getElementById("portal-hotspot-data");
const hotspotMapNode = document.querySelector("[data-hotspot-map]");
const hotspotEmptyNode = document.querySelector("[data-hotspot-empty]");
const hotspotMaximizeButton = document.querySelector("[data-map-maximize]");

if (hotspotDataNode && hotspotMapNode) {
  const reports = JSON.parse(hotspotDataNode.textContent || "[]");
  try {
    console.log(reports);
} catch (e) {
    console.error(e);
}
  const hasLeaflet = typeof window.L !== "undefined";

  if (hotspotEmptyNode) {
    hotspotEmptyNode.classList.toggle("is-visible", reports.length === 0 || !hasLeaflet);
  }

  if (hasLeaflet) {
    const firstReport = reports[0];
    const initialCenter = firstReport
      ? [firstReport.latitude, firstReport.longitude]
      : [-6.7924, 39.2083];
    const initialZoom = firstReport ? 17 : 12;
    const map = window.L.map(hotspotMapNode, {
      zoomControl: true,
      scrollWheelZoom: true,
      minZoom: 12,
    }).setView(initialCenter, initialZoom);

    window.L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: "&copy; OpenStreetMap contributors",
    }).addTo(map);

   const markerLayer = window.L.markerClusterGroup({
  showCoverageOnHover: false,
  spiderfyOnMaxZoom: true,
  disableClusteringAtZoom: 17,
  maxClusterRadius: 50,
});

map.addLayer(markerLayer);
    const markerBounds = [];
    const createPinIcon = (timeBucket) =>
      window.L.divIcon({
        className: `portal-location-pin is-${timeBucket}`,
        html: '<span class="portal-location-pin-head"></span><span class="portal-location-pin-dot"></span>',
        iconSize: [34, 46],
        iconAnchor: [17, 43],
        popupAnchor: [0, -42],
      });

    const marker = window.L.marker([report.latitude, report.longitude], {
    icon: createPinIcon(report.time_bucket),
    title: `${report.reference} - ${report.area}`,
}).addTo(markerLayer);

window.L.circle([report.latitude, report.longitude], {
    radius: 120,
    color: "#DC2626",
    weight: 2,
    fillColor: "#EF4444",
    fillOpacity: 0.18,
}).addTo(markerLayer);

     marker.bindPopup(
       `<div class="portal-map-popup">` +
      `<strong>${escapeHtml(report.reference)}</strong>` +
        `<span>${escapeHtml(report.category)}</span>` +
       `<span>${escapeHtml(report.location_type)} - ${escapeHtml(report.area)}</span>` +
       `<span>${escapeHtml(report.occurred_at)}</span>` +
       `<small>${Number(report.latitude).toFixed(5)}, ${Number(report.longitude).toFixed(5)}</small>` +
       `<a class="portal-map-popup-link" href="https://www.google.com/maps/search/?api=1&query=${report.latitude},${report.longitude}" target="_blank" rel="noopener noreferrer">Open in Google Maps</a>` +
       `</div>`,
       );
      marker.on("click", () => {
        map.setView([report.latitude, report.longitude], 17, { animate: true });
      });
      markerBounds.push([report.latitude, report.longitude]);
    };

    if (markerBounds.length > 1) {
      const approvedBounds = window.L.latLngBounds(markerBounds);
      map.fitBounds(approvedBounds, { padding: [44, 44], maxZoom: 17 });
      map.setMaxBounds(approvedBounds.pad(0.45));
    } else if (markerBounds.length === 1) {
      const [lat, lng] = markerBounds[0];
      const neighborhoodBounds = window.L.latLngBounds([
        [lat - 0.035, lng - 0.035],
        [lat + 0.035, lng + 0.035],
      ]);
      map.setMaxBounds(neighborhoodBounds);
      map.setView(markerBounds[0], 17);
      markerLayer.eachLayer((marker) => marker.openPopup());
    }

    if (hotspotMaximizeButton) {
      hotspotMaximizeButton.addEventListener("click", () => {
        const stage = hotspotMapNode.closest(".portal-real-map-stage");
        if (!stage) {
          return;
        }
        stage.classList.toggle("is-fullscreen");
        document.body.classList.toggle("portal-map-expanded", stage.classList.contains("is-fullscreen"));
        hotspotMaximizeButton.textContent = stage.classList.contains("is-fullscreen")
          ? "Exit fullscreen"
          : "Maximize map";
        setTimeout(() => map.invalidateSize(), 180);
      });
    }

    setTimeout(() => map.invalidateSize(), 100);
  }


const reportMiniMapNodes = document.querySelectorAll("[data-report-mini-map]");

if (reportMiniMapNodes.length && typeof window.L !== "undefined") {
  const createMiniPinIcon = (timeBucket) =>
    window.L.divIcon({
      className: `portal-location-pin portal-location-pin-review is-${timeBucket || "afternoon"}`,
      html: '<span class="portal-location-pin-head"></span><span class="portal-location-pin-dot"></span>',
      iconSize: [34, 46],
      iconAnchor: [17, 43],
      popupAnchor: [0, -42],
    });

  const initializeReportMap = (node) => {
    if (node.dataset.mapReady === "true") {
      return node._portalLeafletMap;
    }

    const lat = Number(node.dataset.lat);
    const lng = Number(node.dataset.lng);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return;
    }

    node.dataset.mapReady = "true";
    node.textContent = "";

    const map = window.L.map(node, {
      zoomControl: true,
      scrollWheelZoom: false,
      minZoom: 14,
      maxBoundsViscosity: 0.75,
    }).setView([lat, lng], 15);
    node._portalLeafletMap = map;

    window.L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: "&copy; OpenStreetMap contributors",
    }).addTo(map);

    const nearbyArea = window.L.circle([lat, lng], {
      radius: 650,
      color: "#d64686",
      weight: 2,
      fillColor: "#ef78a9",
      fillOpacity: 0.12,
    }).addTo(map);

    const reference = node.dataset.reference || "Incident";
    const category = node.dataset.category || "Incident report";
    const area = node.dataset.area || "Area context missing";

    const marker = window.L.marker([lat, lng], {
      icon: createMiniPinIcon(node.dataset.timeBucket),
      title: `${reference} - ${area}`,
    })
      .addTo(map)
      .bindPopup(
        `<div class="portal-map-popup">` +
          `<strong>${escapeHtml(reference)}</strong>` +
          `<span>${escapeHtml(category)}</span>` +
          `<span>${escapeHtml(area)}</span>` +
          `<small>${lat.toFixed(5)}, ${lng.toFixed(5)}</small>` +
          `</div>`,
      )
      .openPopup();

    const mapBounds = window.L.latLngBounds([
    [lat - 0.01, lng - 0.01],
    [lat + 0.01, lng + 0.01],
   ]);

   map.setView([lat, lng], 16);
   map.setMaxBounds(mapBounds);

   node._portalMapBounds = mapBounds;
    node._portalIncidentMarker = marker;
   node._portalNearbyArea = nearbyArea;

    const refreshMap = () => {
     map.invalidateSize();
      map.setView([lat, lng], 16);
      marker.openPopup();
    };

    requestAnimationFrame(refreshMap);
    setTimeout(refreshMap, 150);
    setTimeout(refreshMap, 450);
    return map;
  };

  if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            initializeReportMap(entry.target);
            observer.unobserve(entry.target);
          }
        });
      },
      { rootMargin: "160px" },
    );

    reportMiniMapNodes.forEach((node) => observer.observe(node));
  } else {
    reportMiniMapNodes.forEach(initializeReportMap);
  }

  document.querySelectorAll("[data-report-map-maximize]").forEach((button) => {
    button.addEventListener("click", () => {
      const shell = button.closest(".portal-report-map-shell");
      const mapNode = shell?.querySelector("[data-report-mini-map]");
      if (!shell || !mapNode) {
        return;
      }

      const map = initializeReportMap(mapNode);
      const isFullscreen = !shell.classList.contains("is-fullscreen");
      shell.classList.toggle("is-fullscreen", isFullscreen);
      document.body.classList.toggle("portal-map-expanded", isFullscreen);
      button.textContent = isFullscreen ? "Exit fullscreen" : "Maximize map";
      const refreshFullscreenMap = () => {
        map?.invalidateSize({ pan: false });
        if (mapNode._portalMapBounds) {
          map?.fitBounds(mapNode._portalMapBounds, {
            padding: isFullscreen ? [64, 64] : [24, 24],
            maxZoom: isFullscreen ? 16 : 15,
          });
        }
        mapNode._portalIncidentMarker?.openPopup();
      };
      requestAnimationFrame(refreshFullscreenMap);
      setTimeout(refreshFullscreenMap, 180);
      setTimeout(refreshFullscreenMap, 500);
    });
  });
}
