# stocker queries

## Predictions

```sql
SELECT
  symbol,
  prediction_date,
  after_closing_price,
  predicted_price
FROM stocker.price_prediction
group by
  symbol,
  prediction_date,
  after_closing_price,
  predicted_price
order by 1, 2
```

