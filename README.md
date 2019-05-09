# stocker

Using tweeter sentiment and stock market price signal correlation to predict next day closing price.

> Note, this is for demonstration purposes only. I know literally nothing about the stock market. You should not use this demo to make or support your financial decisions. DON'T DO IT!

Dependant components

* [stockercm](https://github.com/mchmarny/stockercm) - Twitter data source
* [stockermart](https://github.com/mchmarny/stockermart) = Stock market data downloader
* [stockercm](https://github.com/mchmarny/stockercm) - Sentiment processor

Once you get the data flow configured using these components, you can follow the following linear regression model creation, its evaluation against your data set, and running predictions using the trained model.

## Create Model

```sql
#standardSQL
CREATE OR REPLACE MODEL stocker.price_model
OPTIONS
  (model_type='linear_reg', input_label_cols=['price']) AS
SELECT
  p.price,
  p.closingPrice as prev_price,
  c.symbol,
  c.magnitude * c.score as sentiment,
  CAST(c.retweet AS INT64) as retweet
FROM stocker.content c
JOIN stocker.price p on c.symbol = p.symbol
  AND FORMAT_TIMESTAMP('%Y-%m-%d', c.created) = FORMAT_TIMESTAMP('%Y-%m-%d', p.quotedAt)
WHERE c.score <> 0
AND RAND() < 0.01
```

results in

```shell
This statement created a new model named stocker.price_model
```


## Evaluate model

```sql
#standardSQL
INSERT stocker.price_mode_eval (
   eval_ts,
   mean_absolute_error,
   mean_squared_error,
   mean_squared_log_error,
   median_absolute_error,
   r2_score,
   explained_variance
) WITH T AS (
  SELECT
    *
  FROM
    ML.EVALUATE(MODEL stocker.price_model,(
      SELECT
        p.price,
        p.closingPrice as prev_price,
        c.symbol,
        c.magnitude * c.score as sentiment,
        CAST(c.retweet AS INT64) as retweet
      FROM stocker.content c
      JOIN stocker.price p on c.symbol = p.symbol
        AND FORMAT_TIMESTAMP('%Y-%m-%d', c.created) = FORMAT_TIMESTAMP('%Y-%m-%d', p.quotedAt)
      WHERE c.score <> 0
  ))
)
SELECT
  CURRENT_TIMESTAMP(),
  mean_absolute_error,
  mean_squared_error,
  mean_squared_log_error,
  median_absolute_error,
  r2_score,
  explained_variance
FROM T
```

results in

```shell
mean_absolute_error	 mean_squared_error	 mean_squared_log_error	 median_absolute_error	r2_score            explained_variance
3.2502161606238453   227.0738450661901   0.008387276788977339    0.12880176496196327    0.9990422574648288  0.999079865551752
```

> The R2 score is a statistical measure that determines if the linear regression predictions approximate the actual data. 0 indicates that the model explains none of the variability of the response data around the mean. 1 indicates that the model explains all the variability of the response data around the mean.

# Use your model to predict stock price

```sql
#standardSQL
INSERT stocker.price_prediction (
   symbol,
   prediction_date,
   after_closing_price,
   predicted_price
) WITH T AS (

  SELECT
      dt.symbol as symbol,
      p.closingPrice as after_closing_price,
      ROUND(AVG(dt.predicted_price),2) as predicted_price
  FROM
    ML.PREDICT(MODEL stocker.price_model,
      (
      SELECT
        p.price,
        p.closingPrice as prev_price,
        c.symbol,
        c.magnitude * c.score as sentiment,
        CAST(c.retweet AS INT64) as retweet
      FROM stocker.content c
      JOIN stocker.price p on c.symbol = p.symbol
        AND FORMAT_TIMESTAMP('%Y-%m-%d', c.created) = FORMAT_TIMESTAMP('%Y-%m-%d', p.quotedAt)
  )) dt
  join stocker.price p on p.symbol =  dt.symbol
  where p.closingDate = FORMAT_TIMESTAMP('%Y-%m-%d', CURRENT_TIMESTAMP(), "America/Los_Angeles")
  group by
    dt.symbol,
    p.closingPrice

)
SELECT
   symbol,
   FORMAT_TIMESTAMP('%Y-%m-%d', CURRENT_TIMESTAMP(), "America/Los_Angeles"),
   after_closing_price,
   predicted_price
FROM T
```

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