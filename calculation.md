We want each SELL to lose 5.2% of its value every 262800 blocks:

```python
total_loss_percentage = 5.2  # 5.2% total loss
total_blocks = 262800  # Total number of blocks
```

To find the loss per block, we can use the formula for compound interest decay, treating each block as a period.

The formula for compound decay over n periods is `A = P(1 - r)^n`, where: `A` is the final amount, `P` is the initial amount (which we can set to 100 for simplicity), `r` is the rate of decay per period, and `n` is the number of periods. We want to find `r` such that `A = 100 - 5.2` (since we're losing 5.2%).

Rearranging the formula to solve for `r` gives us `r = 1 - (A/P)^(1/n)`.

Here, `A/P = (100 - 5.2)/100 = 0.948` (since we're considering the loss as a percentage of the initial value).

`A_over_P = (100 - total_loss_percentage) / 100`

Solving for r:

```python
r = 1 - (A_over_P ** (1 / total_blocks))
loss_per_block_percentage = r * 100  # Converting the decay rate per block to a percentage
```