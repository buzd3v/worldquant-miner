# Alpha Generation Analysis and Improvement Report

This report analyzes the alpha generation process in the `naive-ollama` repository and provides recommendations to improve the quality and success rate of generated alphas.

## 1. Key Findings

### 1.1. LLM Prompt Format

The prompt sent to the Ollama LLM is located in the `generate_alpha_ideas_with_ollama` function within `alpha_generator_ollama.py`.

**Prompt Structure:**

```
Generate 5 unique alpha factor expressions using the available operators and data fields. Return ONLY the expressions, one per line, with no comments or explanations.

Available Data Fields:
[...]

Available Operators by Category:
Time Series:
[...]

Cross Sectional:
[...]

Arithmetic:
[...]

Logical:
[...]

Vector:
[...]

Transformational:
[...]

Group:
[...]

Requirements:
1. Let your intuition guide you.
2. Use the operators and data fields to create a unique and potentially profitable alpha factor.
3. Anything is possible 42.

Tips:
- You can use semi-colons to separate expressions.
- Pay attention to operator types (SCALAR, VECTOR, MATRIX) for compatibility.
- Study the operator definitions and descriptions to understand their behavior.

Example format:
ts_std_dev(cashflow_op, 180)
rank(divide(revenue, assets))
market_ret = ts_product(1+group_mean(returns,1,market),250)-1;rfr = vec_avg(fnd6_newqeventv110_optrfrq);expected_return = rfr+beta_last_360_days_spy*(market_ret-rfr);actual_return = ts_product(returns+1,250)-1;actual_return-expected_return
```

### 1.2. WorldQuant API Validation Logic

The repository uses two different sets of criteria for validating alphas:

**A. LLM-Generated Alphas (`alpha_generator_ollama.py`)**

- A generated alpha is considered "hopeful" if its `fitness` score is greater than `0.5`.

**B. Brute-Force Mined Alphas (`machine_miner.py`)**

- This script uses a much stricter set of rules. An alpha is considered successful if it meets all the following conditions:
  - `sharpe > 1.25`
  - `turnover > 0.01`
  - `turnover < 0.7`
  - `fitness >= 1.0`

The significant gap between these two validation strategies is a likely reason why many LLM-generated alphas are logged as "hopeful" but are ultimately not viable for submission.

## 2. Recommendations for Improvement

### 2.1. Enhance the LLM Prompt

The current prompt is good, but it can be improved by providing more specific constraints based on what makes a successful alpha.

**Suggested New Prompt:**

```
Generate 5 unique, high-quality alpha factor expressions for the US market. Return ONLY the expressions, one per line.

**Guidelines for High-Quality Alphas:**
- **High Sharpe Ratio:** Aim for expressions that are likely to have a Sharpe ratio greater than 1.5.
- **Low Turnover:** Keep turnover low, ideally between 0.05 and 0.4. Avoid overly complex expressions that trade too frequently.
- **Low Correlation:** The expression should be novel and not highly correlated with common factors (e.g., simple momentum or value).
- **Use Delay > 0:** All time-series operations must use a delay of 1 or greater.
- **Combine Factors:** Try combining different types of data (e.g., fundamental, technical, sentiment) to create more robust alphas.

**Available Data Fields:**
[...]

**Available Operators by Category:**
[...]

**Example of a good alpha structure:**
- `ts_rank(correlation(rank(adv20), rank(close), 5), 5)`
- `(rank(ts_argmax(close, 5)) * -1)`

Now, generate 5 new and unique alpha expressions.
```

### 2.2. Unify and Strengthen Validation Criteria

The validation criteria for LLM-generated alphas should be brought closer to the stricter rules used by the `machine_miner.py`. This will ensure that only genuinely promising alphas are passed to the refinement stage.

**Recommendation:**

In `alpha_generator_ollama.py`, modify the `check_pending_results` function to use a stricter filter:

```python
# In alpha_generator_ollama.py -> check_pending_results()

# ... inside the loop after fetching alpha_data
fitness = alpha_data.get("is", {}).get("fitness")
sharpe = alpha_data.get("is", {}).get("sharpe")
turnover = alpha_data.get("is", {}).get("turnover")

# New, stricter criteria
if (fitness is not None and fitness > 0.8 and
    sharpe is not None and sharpe > 1.0 and
    turnover is not None and turnover < 0.6):
    logging.info(f"Found promising alpha! Fitness: {fitness}, Sharpe: {sharpe}")
    self.log_hopeful_alpha(info["alpha"], alpha_data)
    successful += 1
```

### 2.3. Parallelize Sequential Miners

The scripts `alpha_expression_miner_continuous.py` and `machine_miner.py` test thousands of alpha variations in a slow, single-threaded loop. This is a major performance bottleneck.

**Recommendation:**

Refactor these scripts to use a concurrent submission pattern with `ThreadPoolExecutor`, similar to the one already implemented in `alpha_generator_ollama.py`. This will dramatically increase the number of alphas you can test.

### 2.4. Optimize GPU Resource Allocation

The `docker-compose.yml` file incorrectly allocates expensive GPU resources to services that are I/O-bound (making API calls) and do not perform any GPU computation.

**Recommendation:**

Modify `docker-compose.yml` and `docker-compose.gpu.yml` to ensure that GPU resources are **only** allocated to the `ollama` service. Remove the `deploy` section with `gpu` resources from the following services:
- `alpha-generator`
- `alpha-expression-miner`
- `machine-miner`

This will free up significant VRAM, reduce operational costs, and allow the LLM to run more efficiently.

### 2.5. Implement a Feedback Loop for Near Misses

Many generated alphas might be close to successful but fail on one criterion (e.g., slightly too high turnover). Instead of discarding them, you can feed them back to the LLM for refinement.

**Recommendation:**

1.  Create a new log file, `near_misses.json`, for alphas that meet a "good but not great" criteria (e.g., `sharpe > 1.0` but `turnover > 0.6`).
2.  Create a new "refiner" prompt for the LLM.
3.  Add a new function that periodically takes a near-miss alpha and sends it to the LLM with the refiner prompt.

**Example Refiner Prompt:**

```
The following alpha expression is promising but has a turnover that is too high. Modify the expression to reduce its turnover while trying to maintain or improve its Sharpe ratio. Return ONLY the modified expression.

Original Expression:
`ts_rank(correlation(rank(adv20), rank(close), 5), 5)`

Suggestions for reducing turnover:
- Increase the window in time-series operators (e.g., `ts_rank` from 5 to 10).
- Apply a smoothing operator like `ts_mean`.

Modified Expression:
```

### 2.6. External Learning Resources

To further improve the conceptual underpinnings of your alpha generation, consider these resources:

- **Book:** "Finding Alphas" by WorldQuant's CEO.
- **Online Course:** The "Learn2Quant" series available on the WorldQuant BRAIN platform.

By implementing these changes, you should see a significant improvement in the quality and submission-worthiness of the alphas generated by your system.
