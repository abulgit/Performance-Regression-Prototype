module benchmark_runner;

import std.stdio;
import std.process;
import std.datetime.stopwatch;
import std.datetime;
import std.file;
import std.path;
import std.algorithm;
import std.array;
import std.conv;

import config;

/**
 * Stores all the measurements from one benchmark run
 * Mostly timing info but also other metrics like binary size
 */
struct BenchmarkResult {
    string benchmarkName;
    string compilerVersion;
    SysTime timestamp;
    double compilationTimeSeconds;
    ulong memoryUsageBytes;   // Not currently used but should be added
    ulong binarySize;

    // These are for future use - would need DMD changes to get them
    double lexingTimeSeconds;
    double parsingTimeSeconds;
    double semanticTimeSeconds;
    double codegenTimeSeconds;

    string toCSV() {
        import std.format : format;
        return format("%s,%s,%s,%.3f,%d,%d,%.3f,%.3f,%.3f,%.3f",
            benchmarkName,
            compilerVersion,
            timestamp.toISOExtString(),
            compilationTimeSeconds,
            memoryUsageBytes,
            binarySize,
            lexingTimeSeconds,
            parsingTimeSeconds,
            semanticTimeSeconds,
            codegenTimeSeconds
        );
    }

    static string csvHeader() {
        return "benchmark,compiler,timestamp,compilation_time,memory_usage,binary_size,lexing_time,parsing_time,semantic_time,codegen_time";
    }
}

/**
 * Does the actual benchmark running
 * Responsible for compiling code and measuring performence
 */
class BenchmarkRunner {
    private BenchmarkConfig config;

    this(BenchmarkConfig config) {
        this.config = config;
    }

    /**
     * Runs one benchmark with a specific compiler
     * Returns the performance metrics it measured
     */
    BenchmarkResult runBenchmark(string benchmarkName, string compilerPath) {
        BenchmarkResult result;
        result.benchmarkName = benchmarkName;
        result.compilerVersion = compilerPath;
        result.timestamp = Clock.currTime();

        string benchmarkDir = config.getBenchmarkPath(benchmarkName);
        string[] dFiles = dirEntries(benchmarkDir, "*.d", SpanMode.shallow)
                          .map!(e => e.name)
                          .array();

        if (dFiles.empty) {
            writefln("Warning: No D files found in benchmark %s", benchmarkName);
            return result;
        }

        string outputPath = buildPath(tempDir(), benchmarkName ~ ".exe");

        StopWatch sw;
        sw.start();
        auto pid = spawnProcess([
            compilerPath,
            "-of=" ~ outputPath,
            "-O", // Turn on optimizations
            "-inline", // Make sure inlining is on
            "-release", // Release mode is fastest
        ] ~ dFiles);
        auto status = pid.wait();
        sw.stop();

        if (status != 0) {
            writefln("Error: Compilation failed for benchmark %s", benchmarkName);
            result.compilationTimeSeconds = -1;
            return result;
        }

        result.compilationTimeSeconds = sw.peek().total!"msecs" / 1000.0;

        if (exists(outputPath)) {
            result.binarySize = getSize(outputPath);
        }

        // TODO: Add memory usage and other metrics later
        // Would need to hook into the compiler or use external tools

        return result;
    }

    /**
     * Calcualtes the % difference between baseline and PR results
     * Positive number means PR is slower (regression)
     */
    double calculatePerformanceDifference(BenchmarkResult baseline, BenchmarkResult pr) {
        if (baseline.compilationTimeSeconds <= 0 || pr.compilationTimeSeconds <= 0) {
            return 0.0;
        }

        return (pr.compilationTimeSeconds - baseline.compilationTimeSeconds) /
               baseline.compilationTimeSeconds * 100.0;
    }

    /**
     * Appends results to the CSV file for this benchmark
     * Creates a new file if it doesn't exist yet
     */
    void saveResults(BenchmarkResult[] results, string benchmarkName) {
        string resultPath = config.getResultPath(benchmarkName) ~ ".csv";
        bool fileExists = exists(resultPath);

        File f = File(resultPath, "a");
        if (!fileExists) {
            f.writeln(BenchmarkResult.csvHeader());
        }

        foreach (result; results) {
            f.writeln(result.toCSV());
        }

        f.close();
    }
}