module app;

import std.stdio;
import std.file;
import std.path;
import std.array;
import std.algorithm;
import std.getopt;
import std.process : environment;
import std.string : strip, split;

import config;
import benchmark_runner;
import dashboard_generator;

// The differnet benchmark types we support
enum BenchmarkCategory {
    RealWorld,   // Real stuff like Phobos, vibe.d, etc
    Synthetic,   // Artifical tests for stressing specific features
    Micro        // Tiny benchamrks for compiler components
}

// Info about a benchmark we found in the benchmark dir
struct BenchmarkInfo {
    string name;
    BenchmarkCategory category;
    string description;
}

void main(string[] args) {
    string baselineCompiler = "";
    string testCompiler = "";
    bool generateDashboard = false;
    bool verbose = false;

    auto helpInformation = getopt(
        args,
        "baseline|b", "Baseline compiler path (master branch)", &baselineCompiler,
        "test|t", "Test compiler path (PR or branch under test)", &testCompiler,
        "dashboard|d", "Generate dashboard HTML", &generateDashboard,
        "verbose|v", "Enable verbose logging", &verbose
    );

    if (helpInformation.helpWanted) {
        defaultGetoptPrinter(
            "D Language Performance Regression Publisher\n" ~
            "Usage: performance-publisher [options]\n",
            helpInformation.options
        );
        return;
    }

    config.config.baselineCompilerPath = baselineCompiler;
    config.config.testCompilerPath = testCompiler;
    config.config.verboseLogging = verbose;

    // Extra stuff for GitHub Actions - not fully tested yet
    if (environment.get("GITHUB_ACTIONS", "false") == "true") {
        config.config.githubToken = environment.get("GITHUB_TOKEN", "");
        writeln("Running in GitHub Actions environment");
    }

    if (!exists(config.config.resultsPath)) {
        mkdirRecurse(config.config.resultsPath);
    }

    auto runner = new BenchmarkRunner(config.config);

    auto benchmarks = discoverBenchmarks();
    writefln("Discovered %d benchmarks", benchmarks.length);

    foreach (benchmark; benchmarks) {
        writefln("Running benchmark: %s (%s)", benchmark.name, benchmark.description);

        BenchmarkResult[] results;

        if (config.config.baselineCompilerPath.length > 0) {
            writefln("  Running with baseline compiler: %s", config.config.baselineCompilerPath);
            auto baselineResult = runner.runBenchmark(benchmark.name, config.config.baselineCompilerPath);
            results ~= baselineResult;

            writefln("  Baseline compilation time: %.3f seconds", baselineResult.compilationTimeSeconds);
            writefln("  Baseline binary size: %d bytes", baselineResult.binarySize);
        }

        if (config.config.testCompilerPath.length > 0) {
            writefln("  Running with test compiler: %s", config.config.testCompilerPath);
            auto testResult = runner.runBenchmark(benchmark.name, config.config.testCompilerPath);
            results ~= testResult;

            writefln("  Test compilation time: %.3f seconds", testResult.compilationTimeSeconds);
            writefln("  Test binary size: %d bytes", testResult.binarySize);

            // Show the difference if we have both results
            if (config.config.baselineCompilerPath.length > 0) {
                double timeDiff = runner.calculatePerformanceDifference(results[0], results[1]);
                writefln("  Performance difference: %.2f%%", timeDiff);

                // Warn about big performance changes
                if (timeDiff > 5.0) {
                    writeln("  WARNING: Significant performance regression detected!");
                } else if (timeDiff < -5.0) {
                    writeln("  IMPROVEMENT: Significant performance improvement detected!");
                }
            }
        }

        if (!results.empty) {
            runner.saveResults(results, benchmark.name);
            writeln("  Results saved.");
        }
    }

    if (generateDashboard) {
        writeln("Generating performance dashboard...");
        auto dashboardGenerator = new DashboardGenerator(config.config);
        dashboardGenerator.generateDashboard();
    }

    writeln("Performance testing completed successfully");
}

/**
 * Scans the benchmark dir to find all available benchmarks
 * Tries to read the metadata file but has fallbacks if its missing
 */
BenchmarkInfo[] discoverBenchmarks() {
    BenchmarkInfo[] benchmarks;

    if (!exists(config.config.benchmarkPath)) {
        writefln("Creating benchmark directory: %s", config.config.benchmarkPath);
        mkdirRecurse(config.config.benchmarkPath);
    }

    foreach (dirEntry; dirEntries(config.config.benchmarkPath, SpanMode.shallow)) {
        if (dirEntry.isDir) {
            string metadataPath = buildPath(dirEntry.name, "benchmark.info");
            BenchmarkInfo info;
            info.name = baseName(dirEntry.name);

            if (exists(metadataPath)) {
                auto content = readText(metadataPath).strip();
                auto parts = content.split(":");

                if (parts.length >= 2) {
                    // Figure out the category
                    switch (parts[0]) {
                        case "realworld":
                            info.category = BenchmarkCategory.RealWorld;
                            break;
                        case "synthetic":
                            info.category = BenchmarkCategory.Synthetic;
                            break;
                        case "micro":
                            info.category = BenchmarkCategory.Micro;
                            break;
                        default:
                            // Just gues synthetic if we don't understand it
                            info.category = BenchmarkCategory.Synthetic;
                    }

                    info.description = parts[1];
                } else {
                    // Fallback if file format is wrong
                    info.category = BenchmarkCategory.Synthetic;
                    info.description = "Unknown benchmark";
                }
            } else {
                // No metadata file, use defaults
                info.category = BenchmarkCategory.Synthetic;
                info.description = "Unknown benchmark";
            }

            benchmarks ~= info;
        }
    }

    return benchmarks;
}