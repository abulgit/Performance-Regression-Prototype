# D Language Performance Regression Publisher

This is a tool I wrote to track DMD compiler performance and catch any regressions before they make it into the main codebase. We all know compilation speed is one of D's selling points, so we need to keep an eye on it!

## What it does

Basically, this tool:

1. Runs benchmarks on different DMD versions to compare them
2. Flags any PRs that make the compiler slower (nobody wants that!)
3. Creates some nice charts and graphs so we can see trends
4. Helps contributors understand the performance impact of their code

## Getting it running

### Stuff you'll need first

- DMD or LDC compiler (I've been using LDC lately, it's a bit faster)
- DUB
- Git (obviously)

### Setting it up

1. Grab the code:
   ```powershell
   git clone https://github.com/yourusername/performance-regression-publisher.git
   cd performance-regression-publisher
   ```

2. Build it:
   ```powershell
   dub build --build=release
   ```
   You might see some warnings - don't worry about those.

## How to use it

### Running benchmrks on your machine

If you want to test two DMD versions against each other:

```powershell
./bin/performance-regression-publisher --baseline=path/to/dmd/master --test=path/to/dmd/branch
```

To get a nice dashboard with charts (this is the good stuff):

```powershell
./bin/performance-regression-publisher --baseline=path/to/dmd/master --test=path/to/dmd/branch --dashboard
```

Check out the `dashboard/index.html` file in your browser when it's done!

### Command line options

- `--baseline` or `-b`: Your reference DMD (usually master branch)
- `--test` or `-t`: The DMD you want to test (your branch or PR)
- `--dashboard` or `-d`: Makes pretty HTML charts
- `--verbose` or `-v`: More output (useful when something breaks)

### Making new benchmarks

Want to add more benchmarks? Put them in the `benchmarks` directory with:

1. A `benchmark.info` file with `category:description`
2. Some D code that's representative of what you want to test

The folder structure should be like:
```
benchmarks/
  template_heavy/         <- templates are notoriously slow sometimes
    benchmark.info
    main.d
  large_switch/           <- This one tests big switch statements
    benchmark.info
    main.d
```

## Types of benchmarks

I've set up three types (but feel free to add more):

- **RealWorld**: Actual D code people use (Phobos, etc)
- **Synthetic**: Artificial tests that stress specific features
- **Micro**: Tiny benchmarks for specific compiler parts

## CI Integration

There's GitHub Actions workflow stuff so it can run automatically on DMD PRs. I haven't fully tested this part yet, so it might need some tweaking.

## Project layout

- `src/`: The actual D code for the tool
- `benchmarks/`: Test cases (add more here!)
- `results/`: CSV files with benchmark data
- `dashboard/`: The HTML output with graphs
- `.github/workflows/`: CI stuff

## Dev build

If you're hacking on the tool itself:

```powershell
dub build --build=debug
```
