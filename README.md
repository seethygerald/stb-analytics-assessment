### Deliverables:

## Code: tourism-analysis.ipynb
## Narrative: See under /presentation folder
## readme.txt: See below:

# a. Briefly explain the external dataset(s) you chose and why

My external dataset utilized AI to help compile list of concerts held in Singapore by major international/regional acts since 2008.

Why did I choose the above? I initially began my research with two hypotheses which I have been meaning to answer for myself:

1. Higher average room rates are associated with a situation where airport arrivals Year-on-Year (YoY) growth exceeds tourist arrivals YoY growth (i.e., results in weaker growth in tourist arrivals relative to people who are merely transiting in Singapore) 
2. Concerts are positively associated with stronger YoY growth in tourist arivals for our top 10 tourism markets.

A quick check and I found no statistically significant relationship for (1), so I went ahead with (2).

# b. List the assumptions you made during your analysis (e.g. how you handled missing data, defined a specific metric, etc.)

1. Excluded the COVID-19 years (2020-2022) from my analyses to minimize results being skewed by the atypical plunge and recovery in tourist arrivals during this period. I went ahead with the years 2020 - 2022 because they mimicked the lack of data for some of the STAN datasets.(sometimes I included 2023 as well as if as a result of excluding 2022, there was no corresponding 2022 data (using lag) to facilitate the further anlysis).
2. For length_of_stay, I needed "Visitor Arrivals" to become an integer (BIGINT) so I could perform numerical analysis on it. But the column contained '-', which cannot be converted to an integer. So converted all '-' values to 0.
3. Later I discovered that I had to convert all rows where avg_length_of_stay = 0 if visitor_arrivals = 0 as it does not make sense that avg_length_of_stay for a particular period is non-zero when there were no tourist arrivals in that group for that period. In the grand
scheme of things, this was a minior point, but would help improve accuracy of results nonetheless
4. I cleaned travel_mode but ended up not using it in the end as my hypothesis (1) was no longer useful as mentioned above.
5. In a nutshell, YoY visitor-arrival growth for each country, age group and sex combination was calculated as ((Current Visitors / Previous-Year Visitors) - 1) x 100.
6. Binary t-test (concert vs no concert) - Result significant at the 5% level (p < 0.05) means that if there were actually no difference in average tourist-arrival growth between concert and non-concert months, the probability of observing a difference at least this extreme would be less than 5%, under the assumptions of the test.
7. Concert intensity correlation: Result significant at the 5% level (p < 0.05) means that if there were actually no linear correlation between concert intensity and tourist-arrival growth, the probability of observing a correlation at least this extreme would be less than 5%, under the assumptions of the test.
8. For the tests in (6) and (7), I ignored all combinations with sample data less than 30 to avoid drawing conclusions from very small and unstable samples.

# c. Describe the main challenges you encountered (e.g. data availability,ambiguity in the prompt, technical hurdles). Explain the caveats or limitations of your final analysis because of these challenges.

1. It would have been useful if I had daily data for tourist arrivals broken down by demographic segment (age, sex) instead of monthly. This would allow me to drilldown further on the exact effect of having a concert and tourist arrivals by studying the changes in the period immediately before said concert(s).
2. The data in STAN only dates back to 2008. If I had more data from earlier years, the results of my t-test/correlation tests may be more accurate.
3. My list of concerts was not exhaustive. The list was self-compiled and QC-ed by me with the help of AI, so there are some measurement/selection
biases.

# d. Describe what you would investigate next if you had more time.

1. I would have done a multivariate causal analysis, to analyze whether the observed relationship between concert activity and tourist-arrival growth remained even after controlling for other factors that could influence tourism demand, and if so how significant? This could include hotel room rates, economic conditions in source markets, exchange rates, seasonality, public holidays, major non-concert events, flight capacity and broader travel trends.
2. Given (3) in answer (c), if I had easy access to historical data on Singapore's cultural/tourism calendar, or more time to scrape said data from official sources, would have had a more exhaustive list of events that might allow me to analyze whether there were nuances in the relationships between certain demographic combinations and types of events. For instance, perhaps gaming/nightlife related ecents = more strongly associated with younger/children demographics, concerts = more strongly associated with younger/mid-aged demographics, while artshows/plays/museum-centric events = more associated with older demographics?