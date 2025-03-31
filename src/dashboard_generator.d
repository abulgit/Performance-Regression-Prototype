module dashboard_generator;

import std.stdio;
import std.file;
import std.path;
import std.array;
import std.algorithm;
import std.string;
import std.conv;
import std.datetime;

import config;
import benchmark_runner;

/**
 * Handles creating the HTML dashboard to visualise performace data
 * Made this class to seperate dashboard logic from the benchmarking
 */
class DashboardGenerator {
    private BenchmarkConfig config;

    this(BenchmarkConfig config) {
        this.config = config;
    }

    /**
     * Generates the entire dashboard with all graphs and tables
     * This is the main entry point for dashboard creation
     */
    void generateDashboard() {
        writeln("Generating performance dashboard...");

        string dashboardDir = "dashboard";
        if (!exists(dashboardDir)) {
            mkdirRecurse(dashboardDir);
        }

        auto benchmarkResults = collectResults();
        generateIndexPage(dashboardDir, benchmarkResults);

        foreach (benchmarkName, results; benchmarkResults) {
            generateBenchmarkPage(dashboardDir, benchmarkName, results);
        }

        generateAssets(dashboardDir);

        writeln("Dashboard generated successfully at ", dashboardDir);
    }

    /**
     * Gets all the benchmark results from the CSV files
     * This is kinda messy but it works - could clean up later
     */
    private BenchmarkResult[][string] collectResults() {
        BenchmarkResult[][string] results;

        foreach (csvFile; dirEntries(config.resultsPath, "*.csv", SpanMode.shallow)) {
            string benchmarkName = baseName(csvFile.name, ".csv");
            BenchmarkResult[] benchmarkResults;

            auto f = File(csvFile.name, "r");
            // Skip header
            f.readln();

            string line;
            while ((line = f.readln()) !is null) {
                line = line.chomp();
                auto parts = line.split(",");

                if (parts.length >= 6) {
                    BenchmarkResult result;
                    result.benchmarkName = parts[0];
                    result.compilerVersion = parts[1];
                    result.timestamp = SysTime.fromISOExtString(parts[2]);
                    result.compilationTimeSeconds = to!double(parts[3]);
                    result.memoryUsageBytes = to!ulong(parts[4]);
                    result.binarySize = to!ulong(parts[5]);

                    if (parts.length >= 10) {
                        result.lexingTimeSeconds = to!double(parts[6]);
                        result.parsingTimeSeconds = to!double(parts[7]);
                        result.semanticTimeSeconds = to!double(parts[8]);
                        result.codegenTimeSeconds = to!double(parts[9]);
                    }

                    benchmarkResults ~= result;
                }
            }

            benchmarkResults.sort!((a, b) => a.timestamp > b.timestamp);
            results[benchmarkName] = benchmarkResults;
        }

        return results;
    }

    /**
     * Makes the main dashboard page (index.html)
     * Shows summary data of all benchmarks in one place
     */
    private void generateIndexPage(string dashboardDir, BenchmarkResult[][string] allResults) {
        string indexPath = buildPath(dashboardDir, "index.html");
        auto f = File(indexPath, "w");

        f.writeln(`<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>D Language Performance Dashboard</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <header>
        <h1>D Language Performance Dashboard</h1>
        <p>Last updated: `, Clock.currTime().toISOExtString(), `</p>
    </header>

    <main>
        <div class="dashboard-intro">
            <p>This dashboard tracks the compilation performance of the D programming language compiler (DMD).
            Performance metrics help identify regressions and improvements as the codebase evolves.</p>
        </div>

        <h2>Benchmark Summary</h2>
        <table class="summary-table">
            <thead>
                <tr>
                    <th>Benchmark</th>
                    <th>Latest Compilation Time (s)</th>
                    <th>vs Previous</th>
                    <th>Binary Size (KB)</th>
                </tr>
            </thead>
            <tbody>`);

        foreach (benchmarkName, results; allResults) {
            f.writeln("                <tr>");
            f.writeln(`                    <td><a href="`, benchmarkName, `.html">`, benchmarkName, `</a></td>`);

            if (results.length > 0) {
                f.writefln("                    <td>%.3f</td>", results[0].compilationTimeSeconds);

                if (results.length >= 2) {
                    double diff = (results[0].compilationTimeSeconds - results[1].compilationTimeSeconds) /
                                 results[1].compilationTimeSeconds * 100.0;

                    if (diff > 0) {
                        f.writefln(`                    <td class="regression">+%.2f%%</td>`, diff);
                    } else {
                        f.writefln(`                    <td class="improvement">%.2f%%</td>`, diff);
                    }
                } else {
                    f.writeln("                    <td>N/A</td>");
                }

                f.writefln("                    <td>%.2f</td>", results[0].binarySize / 1024.0);
            } else {
                f.writeln("                    <td>No data</td><td>N/A</td><td>N/A</td>");
            }

            f.writeln("                </tr>");
        }

        f.writeln(`            </tbody>
        </table>

        <div class="dashboard-info">
            <h2>About the Benchmarks</h2>
            <dl>
                <dt>large_switch</dt>
                <dd>Tests compiler performance with large switch statements</dd>

                <dt>template_heavy</dt>
                <dd>Evaluates template instantiation and compile-time function evaluation</dd>

                <dt>phobos_mini</dt>
                <dd>Measures compilation of standard library features</dd>
            </dl>
        </div>
    </main>

    <footer>
        <p>D Language Performance Regression Publisher</p>
    </footer>
</body>
</html>`);

        f.close();
    }

    /**
     * Generate page for one benchmark showing it's details
     * TODO: add more stats like memory usage over time
     */
    private void generateBenchmarkPage(string dashboardDir, string benchmarkName, BenchmarkResult[] results) {
        string pagePath = buildPath(dashboardDir, benchmarkName ~ ".html");
        auto f = File(pagePath, "w");

        f.writeln(`<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>`, benchmarkName, ` - D Language Performance Dashboard</title>
    <link rel="stylesheet" href="styles.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <header>
        <h1>`, benchmarkName, ` Performance</h1>
        <p><a href="index.html">← Back to Dashboard</a></p>
    </header>

    <main>
        <div class="benchmark-summary">
            <h2>Performance Overview</h2>`);

        if (results.length > 0) {
            auto latestResult = results[0];

            f.writeln(`
            <div class="stats-container">
                <div class="stat-box">
                    <span class="stat-label">Latest Compilation Time</span>
                    <span class="stat-value">`, format("%.3f", latestResult.compilationTimeSeconds), ` seconds</span>
                </div>
                <div class="stat-box">
                    <span class="stat-label">Binary Size</span>
                    <span class="stat-value">`, format("%.2f", latestResult.binarySize / 1024.0), ` KB</span>
                </div>`);

            if (results.length >= 2) {
                double diff = (results[0].compilationTimeSeconds - results[1].compilationTimeSeconds) /
                             results[1].compilationTimeSeconds * 100.0;
                string diffClass = diff > 0 ? "regression" : "improvement";

                f.writeln(`
                <div class="stat-box">
                    <span class="stat-label">vs Previous Run</span>
                    <span class="stat-value `, diffClass, `">`, diff > 0 ? "+" : "", format("%.2f", diff), `%</span>
                </div>`);
            }

            f.writeln(`
            </div>`);
        }

        f.writeln(`
        </div>

        <div class="chart-container">
            <canvas id="compilationTimeChart"></canvas>
        </div>

        <h2>Results History</h2>
        <table class="results-table">
            <thead>
                <tr>
                    <th>Date</th>
                    <th>Compiler</th>
                    <th>Compilation Time (s)</th>
                    <th>Memory Usage (MB)</th>
                    <th>Binary Size (KB)</th>
                </tr>
            </thead>
            <tbody>`);

        foreach (result; results) {
            f.writeln("                <tr>");
            f.writefln("                    <td>%s</td>", result.timestamp.toSimpleString());
            f.writefln("                    <td>%s</td>", result.compilerVersion);
            f.writefln("                    <td>%.3f</td>", result.compilationTimeSeconds);
            f.writefln("                    <td>%.2f</td>", result.memoryUsageBytes / (1024.0 * 1024.0));
            f.writefln("                    <td>%.2f</td>", result.binarySize / 1024.0);
            f.writeln("                </tr>");
        }

        auto timestamps = results.map!(r => `"` ~ r.timestamp.toSimpleString() ~ `"`).array().join(", ");
        auto compilationTimes = results.map!(r => format("%.3f", r.compilationTimeSeconds)).join(", ");

        f.writeln(`            </tbody>
        </table>
    </main>

    <footer>
        <p>D Language Performance Regression Publisher</a></p>
    </footer>

    <script>
        // Chart initialization
        document.addEventListener('DOMContentLoaded', function() {
            const ctx = document.getElementById('compilationTimeChart').getContext('2d');
            const chart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: [`, timestamps, `],
                    datasets: [{
                        label: 'Compilation Time (s)',
                        data: [`, compilationTimes, `],
                        borderColor: 'rgb(75, 192, 192)',
                        backgroundColor: 'rgba(75, 192, 192, 0.1)',
                        borderWidth: 2,
                        tension: 0.2,
                        fill: true
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        title: {
                            display: true,
                            text: 'Compilation Time History',
                            font: {
                                size: 16,
                                weight: 'bold'
                            },
                            padding: {
                                top: 10,
                                bottom: 20
                            }
                        },
                        legend: {
                            position: 'bottom'
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Seconds'
                            }
                        },
                        x: {
                            ticks: {
                                maxRotation: 45,
                                minRotation: 45
                            }
                        }
                    }
                }
            });
        });
    </script>
</body>
</html>`);

        f.close();
    }

    /**
     * Make the CSS file to make everything look nice
     * My CSS is not the best but it should work OK!
     */
    private void generateAssets(string dashboardDir) {
        string cssPath = buildPath(dashboardDir, "styles.css");
        auto f = File(cssPath, "w");

        f.writeln(`/* Modern dashboard styles */
body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    line-height: 1.6;
    color: #333;
    max-width: 1200px;
    margin: 0 auto;
    padding: 1.5rem;
    background-color: #f8f9fa;
}

header {
    border-bottom: 2px solid #e9ecef;
    margin-bottom: 2rem;
    padding-bottom: 1rem;
}

header h1 {
    color: #343a40;
    margin-bottom: 0.5rem;
}

footer {
    border-top: 2px solid #e9ecef;
    margin-top: 2rem;
    padding-top: 1rem;
    text-align: center;
    color: #6c757d;
}

.chart-container {
    height: 400px;
    margin-bottom: 2rem;
    background-color: white;
    padding: 1rem;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.12);
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 2rem;
    background-color: white;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 1px 3px rgba(0,0,0,0.12);
}

th, td {
    padding: 0.75rem 1rem;
    text-align: left;
    border-bottom: 1px solid #e9ecef;
}

th {
    background-color: #f1f3f5;
    font-weight: 600;
    color: #495057;
}

.summary-table tr:hover {
    background-color: #f1f3f5;
}

.improvement {
    color: #28a745;
    font-weight: 600;
}

.regression {
    color: #dc3545;
    font-weight: 600;
}

a {
    color: #0366d6;
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
    color: #0056b3;
}

main h2 {
    color: #343a40;
    margin: 1.5rem 0 1rem 0;
}

.results-table {
    font-size: 0.95rem;
}

/* New styles for the enhanced UI */
.dashboard-intro {
    background-color: white;
    padding: 1.5rem;
    border-radius: 8px;
    margin-bottom: 2rem;
    box-shadow: 0 1px 3px rgba(0,0,0,0.12);
}

.dashboard-intro p {
    margin: 0;
    color: #495057;
}

.dashboard-info {
    background-color: white;
    padding: 1.5rem;
    border-radius: 8px;
    margin-top: 2rem;
    box-shadow: 0 1px 3px rgba(0,0,0,0.12);
}

.dashboard-info dt {
    font-weight: 600;
    color: #343a40;
    margin-top: 1rem;
}

.dashboard-info dt:first-child {
    margin-top: 0;
}

.dashboard-info dd {
    margin-left: 0;
    color: #495057;
}

.benchmark-summary {
    background-color: white;
    padding: 1.5rem;
    border-radius: 8px;
    margin-bottom: 2rem;
    box-shadow: 0 1px 3px rgba(0,0,0,0.12);
}

.benchmark-summary h2 {
    margin-top: 0;
    margin-bottom: 1rem;
}

.stats-container {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
}

.stat-box {
    flex: 1;
    min-width: 200px;
    background-color: #f1f3f5;
    padding: 1rem;
    border-radius: 6px;
    display: flex;
    flex-direction: column;
}

.stat-label {
    font-size: 0.9rem;
    color: #6c757d;
    margin-bottom: 0.5rem;
}

.stat-value {
    font-size: 1.5rem;
    font-weight: 600;
    color: #343a40;
}
`);

        f.close();
    }
}