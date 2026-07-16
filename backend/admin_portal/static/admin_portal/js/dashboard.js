document.addEventListener("DOMContentLoaded", () => {

    const categoryNode = document.getElementById("top-categories-data");
    const timeNode = document.getElementById("time-chart-data");

    if (!categoryNode || !timeNode) {
        return;
    }

    const categoryData = JSON.parse(categoryNode.textContent);
    const timeData = JSON.parse(timeNode.textContent);
    // ---------------- LINE CHART ----------------

    const trendCanvas = document.getElementById("incidentTrendChart");

    if (trendCanvas) {

        new Chart(trendCanvas, {
            type: "line",
            data: {
                labels: timeData.map(item => item.label),
                datasets: [{
                    label: "Incident Distribution (%)",
                    data: timeData.map(item => item.percent),
                    borderColor: "#2563EB",
                    backgroundColor: "rgba(37,99,235,.12)",
                    fill: true,
                    tension: .4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                }
            }
        });

    }


    // ---------------- DOUGHNUT ----------------

    const categoryCanvas = document.getElementById("categoryChart");

    if (categoryCanvas) {

        new Chart(categoryCanvas, {

            type: "doughnut",

            data: {

                labels: categoryData.map(item => item.label),

                datasets: [{

                    data: categoryData.map(item => item.count),

                    backgroundColor: [
                        "#2563EB",
                        "#14B8A6",
                        "#F59E0B",
                        "#EF4444"
                    ]

                }]

            },

            options: {

                responsive: true,

                maintainAspectRatio: false,
                cutout: '60%',

                plugins: {

                    legend: {

                        position: "bottom"

                    }

                }

            }

        });

    }

});