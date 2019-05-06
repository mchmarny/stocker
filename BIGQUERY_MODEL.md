# stocker ML

Stocker model


## Create Model

```sql
#standardSQL
CREATE MODEL stocker.price_model
OPTIONS
  (model_type='linear_reg', input_label_cols=['currentPrice']) AS
SELECT
  p.currentPrice,
  c.symbol,
  c.magnitude * c.score as sentiment
FROM stocker.content c
JOIN stocker.price p on c.symbol = p.symbol
  AND FORMAT_TIMESTAMP('%Y-%m-%d', c.created) = FORMAT_TIMESTAMP('%Y-%m-%d', p.quotedAt)
WHERE c.score <> 0
AND RAND() < 0.001
```

results in

```shell
This statement created a new model named stocker.price_model
```


## Evaluate model

```sql
#standardSQL
SELECT
  *
FROM
  ML.EVALUATE(MODEL stocker.price_model,
    (
    SELECT
      p.currentPrice,
      c.symbol,
      c.magnitude * c.score as sentiment
    FROM stocker.content c
    JOIN stocker.price p on c.symbol = p.symbol
      AND FORMAT_TIMESTAMP('%Y-%m-%d', c.created) = FORMAT_TIMESTAMP('%Y-%m-%d', p.quotedAt)
    WHERE c.score <> 0
))
```

results in

```shell
mean_absolute_error	    mean_squared_error	    mean_squared_log_error	median_absolute_error	r2_score  explained_variance
2.7344829173005984E-12  1.2941467966662925E-23  1.066178034902745E-28   1.1368683772161603E-12  1.0       1.0
```

> The R2 score is a statistical measure that determines if the linear regression predictions approximate the actual data. 0 indicates that the model explains none of the variability of the response data around the mean. 1 indicates that the model explains all the variability of the response data around the mean.

# Use your model to predict stock price

```sql
#standardSQL
SELECT
    avg(predicted_currentPrice) as predicted_stock_price
FROM
  ML.PREDICT(MODEL stocker.price_model,
    (
    SELECT
      c.symbol,
      c.magnitude * c.score as sentiment
    FROM stocker.content c
    JOIN stocker.price p on c.symbol = p.symbol
      AND FORMAT_TIMESTAMP('%Y-%m-%d', c.created) = FORMAT_TIMESTAMP('%Y-%m-%d', p.quotedAt)
    WHERE c.symbol = 'GOOGL'
))
```

