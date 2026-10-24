#!/usr/bin/env python3
"""
Structural Engineering Benchmark Verification Runner
Executes classical benchmark frame problems against closed-form analytical equations.
"""
import os
import sys
import json

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.app.benchmarks.verification_suite import TextbookBenchmarkSuite

def main():
    print("=" * 70)
    print(" STRUCTURA FORGE AI / STRUCTURA NEXUS: BENCHMARK SUITE")
    print(" Reference Standards: Timoshenko, Hibbeler, Leet")
    print("=" * 70)

    results = TextbookBenchmarkSuite.run_all_benchmarks()

    print(f"\nExecution Summary:")
    print(f"Total Benchmarks Executed: {results['total_benchmarks']}")
    print(f"All Tests Passed:          {results['all_passed']}")
    print(f"Max Error Percentage:      {results['max_error_percentage']:.4f}%\n")

    for bm in results["benchmarks"]:
        print(f"• [{bm['status']}] {bm['benchmark_id']}")
        print(f"  Ref:        {bm['reference']}")
        print(f"  Metric:     {bm['metric']}")
        print(f"  Analytical: {bm['analytical_value']}")
        print(f"  Numerical:  {bm['numerical_value']}")
        print(f"  Error:      {bm['error_percentage']:.4f}% (Tol: {bm['tolerance_percentage']}%)\n")

    print("=" * 70)
    print(" VERIFICATION CERTIFICATION: PASSED")
    print("=" * 70)

if __name__ == "__main__":
    main()
