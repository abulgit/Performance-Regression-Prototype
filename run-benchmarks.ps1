#!/usr/bin/env pwsh
# PowerShell script to run D Language Performance Regression Publisher benchmarks

# Set strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Default parameters
$baselineCompiler = $null
$testCompiler = $null
$generateDashboard = $false
$verbose = $false

# Parse command line arguments
for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        { $_ -eq "--baseline" -or $_ -eq "-b" } {
            $baselineCompiler = $args[++$i]
        }
        { $_ -eq "--test" -or $_ -eq "-t" } {
            $testCompiler = $args[++$i]
        }
        { $_ -eq "--dashboard" -or $_ -eq "-d" } {
            $generateDashboard = $true
        }
        { $_ -eq "--verbose" -or $_ -eq "-v" } {
            $verbose = $true
        }
        { $_ -eq "--help" -or $_ -eq "-h" } {
            Write-Host "D Language Performance Regression Publisher"
            Write-Host "Usage: ./run-benchmarks.ps1 [options]"
            Write-Host ""
            Write-Host "Options:"
            Write-Host "  --baseline, -b <path>   Path to baseline DMD compiler (usually master branch)"
            Write-Host "  --test, -t <path>       Path to test DMD compiler (PR or branch under test)"
            Write-Host "  --dashboard, -d         Generate HTML dashboard of results"
            Write-Host "  --verbose, -v           Enable verbose logging"
            Write-Host "  --help, -h              Show this help message"
            exit 0
        }
        default {
            Write-Host "Unknown option: $($args[$i])"
            Write-Host "Use --help to see available options"
            exit 1
        }
    }
}
if (-not (Get-Command "dub" -ErrorAction SilentlyContinue)) {
    Write-Host "Error: DUB package manager not found. Please install DUB."
    exit 1
}
if (-not ((Get-Command "dmd" -ErrorAction SilentlyContinue) -or (Get-Command "ldc2" -ErrorAction SilentlyContinue))) {
    Write-Host "Error: No D compiler found. Please install DMD or LDC."
    exit 1
}
Write-Host "Building performance regression publisher..."
& dub build --build=release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to build performance regression publisher."
    exit 1
}

# Prepare arguments for the performance regression publisher
$publisherArgs = @()

if ($baselineCompiler) {
    $publisherArgs += "--baseline=$baselineCompiler"
}

if ($testCompiler) {
    $publisherArgs += "--test=$testCompiler"
}

if ($generateDashboard) {
    $publisherArgs += "--dashboard"
}

if ($verbose) {
    $publisherArgs += "--verbose"
}

Write-Host "Running benchmarks..."

if (-not $baselineCompiler -and -not $testCompiler) {
    Write-Host "Warning: No compilers specified. Using demo mode with fake data."
}

& "./bin/performance-regression-publisher" @publisherArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Benchmark execution failed."
    exit 1
}
if ($generateDashboard) {
    $dashboardPath = Resolve-Path "./dashboard"
    Write-Host "Dashboard generated at: $dashboardPath"
    Write-Host "Open ./dashboard/index.html in a web browser to view the results."
}

Write-Host "Benchmarks completed successfully!"