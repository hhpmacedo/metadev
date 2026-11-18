---
name: ai-feature-testing
description: Testing a feature that calls a language model, or a prompt on its own - checking behaviour instead of exact text, probing bad and hostile input, scoring output, and guarding against regressions. Use when the thing under test produces model output, including chat flows, tool-calling pipelines and prompt changes.
user-invocable: false
---

# AI Feature Testing

A good outcome is evidence that the feature behaves acceptably across repeated runs and across bad input, stated as properties that were checked, with a set of reference cases that will show whether the next change made it worse.

## Required foundations

None.

## Required context

- Required: the acceptance criteria for the feature, including what the model must always do and must never do.
- Required: access to the feature in the environment users will use.
- Required: for a prompt change, the previous version of the prompt, so the two can be compared.
- Optional: the prompt text and the pipeline configuration (step limits, tools, stop conditions).
- Optional: reference responses kept from earlier rounds.

## Approach

1. **Accept that exact-match testing does not apply.** Model output varies between runs, several different outputs can all be correct, a small change in input can produce a large change in output, and the model can do things nobody planned for. Every later step follows from this.
2. **Run the complete flow first.** Confirm that the conversation completes, that tools execute, and that the response is coherent. A tool-calling pipeline with no stop condition is valid code and, with the AI SDK's defaults, stops after the first tool call: the tool runs, no answer text follows, and there is no error. A stop condition that never becomes true loops instead. Only a real run shows either.
3. **Assert behaviour, not strings.**

   ```javascript
   // Too brittle: fails on any rewording
   expect(response).toBe('The capital of France is Paris.');

   // Tests the behaviour
   expect(response).toContain('Paris');
   expect(response.toLowerCase()).toMatch(/capital|city/);
   ```

4. **Write the required properties down and check each one.** Does the output stay on topic? Does it respect length limits? Does it include the required elements? Does it avoid forbidden content?
5. **Test the inputs that go wrong, not only good ones.**

   | Scenario | What to check |
   | --- | --- |
   | Normal use | It works as expected |
   | Empty input | It responds sensibly and does not crash |
   | Very long input | It handles, truncates or rejects it deliberately |
   | Typos, misspellings, different phrasings | The same request still gets the same treatment |
   | Unusual but valid input | It is handled |
   | Ambiguous request | It asks for clarification or makes a reasonable, stated assumption |
   | Out-of-scope request | It recognizes it and declines clearly |
   | Conflicting instructions | It prioritizes in the intended way |
   | Adversarial input | It resists prompt injection and cannot be hijacked |
   | Sensitive content | It is handled appropriately |
   | Long context | It still behaves when the conversation approaches context limits |
   | Failure of the model or a tool | The feature fails cleanly, with a usable message |

   Also check what the feature does when the model returns wrong, empty or off-topic output: the surrounding code must not present it as a good answer or break on it.
6. **Run the same input several times.** One good response proves little. Check that the outputs are consistently acceptable, that the variation is within what the feature can tolerate, and that quality is stable. Record how many runs you made.
7. **Choose the evaluation method that fits the requirement.**
   - Pass or fail, for clear requirements: did it include X, did it avoid Y, did it complete the task.
   - A rubric, for qualitative output: score quality, relevance and clarity from 1 to 5.
   - Comparison, when there are two versions: which is better, why, and what specifically improved.
8. **Review the prompt itself when you have access to it.**
   - Clarity: is the intent clear, would different readers interpret it the same way, are the constraints explicit?
   - Robustness: covered by the input variations in step 5.
   - Safety: can it be hijacked, does it resist injection?
   - Efficiency: is it as short as it can be while staying clear, are there redundant instructions, is context used well?
9. **Keep reference cases for regression.** Save examples of good responses together with their inputs. Use them as a reference, not as an exact match: a new version must be at least as good. Keep a list of key behaviours that worked ("handled X correctly") and re-check each after every prompt, model or pipeline change. New capabilities must not break old ones. Update the references when the requirements change.
10. **Report the result.** State the properties checked, the scenarios run, the number of runs per input, the evaluation method, and failures with the exact input that produced them so they can be replayed. Report defects with `bug-reporting`; include the input, the output and how often it occurred.

## Done means

- The complete flow ran to the end in the target environment, and terminated.
- Every "must" and "must never" in the criteria is expressed as a property and has a recorded result.
- Empty, very long, ambiguous, out-of-scope and adversarial inputs were each tried, and the results are recorded.
- Each key input was run more than once and the number of runs is stated.
- No test passes or fails on an exact output string.
- For a changed prompt or model, the reference cases were re-run and each is at least as good as before, or the regression is reported.
- Failures include the exact input and output.

## Anti-patterns

- **Testing only good output.** The failures that reach users are wrong, empty and off-topic responses and the code's handling of them.
- **Exact-string assertions.** They fail on harmless rewording and get deleted, leaving no test at all.
- **Judging from a single run.** A feature that fails one time in five looks fine in one run.
- **Treating reference responses as fixed answers.** They show the standard to meet. Comparing word for word turns every model update into false failures.
- **Stopping at "the page loads".** Type checks and code review do not reveal a misconfigured pipeline. Complete a conversation.
- **Changing a prompt without re-running old cases.** A fix for one input often breaks another that used to work.
