module config;

import std.path : buildPath;
struct BenchmarkConfig {
    string dmdRepoPath = "dmd";
    string resultsPath = "results";
    string benchmarkPath = "benchmarks";
    string baselineCompilerPath;
    string testCompilerPath;
    int iterations = 3;
    string githubToken;
    bool verboseLogging = false;

    /// For our statiscal analysis - needs tuning maybe
    double significanceThreshold = 0.05;

    string getBenchmarkPath(string benchmarkName) {
        return buildPath(benchmarkPath, benchmarkName);
    }

    string getResultPath(string benchmarkName) {
        return buildPath(resultsPath, benchmarkName);
    }
}

BenchmarkConfig config;