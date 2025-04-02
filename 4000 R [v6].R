library(tidyverse) # map_df()
library(jsonlite) # fromJSON()
library(tm) # Corpus(), VectorSource(), tm_map()
library(textstem) # lemmatize_strings()
library(syuzhet) # get_sentiment()
library(treemapify) # geom_treemap()



# (I) READ the 'News_Category_Dataset_v3'
# because each row is a JSON object, we have to read the JSON doc line by line
# and parse each row as an independent JSON object individually into a df in R
news_file_path <- 'News_Category_Dataset_v3.json'
news_lines <- readLines(news_file_path)
news_json_data_df <- map_df(news_lines, ~ fromJSON(.x))

# (II) Graph plotting
# 1.Stacked bar chart: news frequency across year and the % of top 3 + other category
# Aggregate data: Grouping the Top 3 Categories and Categorizing the Rest as “Other”
# Step 1: Prepare data
news_json_data_df$date <- as.Date(news_json_data_df$date, '%Y-%m-%d') # convert 'date' to class 'Date'
news_json_data_df$year_month <- format(news_json_data_df$date, '%Y-%m') # extract the year_month as a new column
news_json_data_df$year <- format(news_json_data_df$date, '%Y') # extract the year as a new column
news_json_data_df$category[news_json_data_df$category == 'CULTURE & ARTS'] <- 'ARTS & CULTURE'
news_json_data_df$category[news_json_data_df$category == 'ARTS'] <- 'ARTS & CULTURE'


top_3_news <- news_json_data_df %>%
  group_by(year, category) %>%
  summarise(count = n(), .groups = 'drop') %>%
  group_by(year) %>%
  arrange(year, desc(count)) %>%
  mutate(rank = row_number()) %>% # rank the categories within each year
  mutate(category = ifelse(rank>3, 'OTHER', category)) %>% # no ties in ranks
  group_by(year, category) %>% # group categories beyond top3 as 'OTHER'
  summarise(count = sum(count)) # group 'OTHER' and recalculate the count
stacked_data <- top_3_news %>%
  group_by(year) %>%
  mutate(proportion = count/sum(count)) %>% # calculate the yearly proportion of each category
  arrange(year, desc(proportion)) %>% # arrange the proportion in descending within each year
  mutate(category = factor(category, levels = unique(category))) # control the plotting order
# Step 2: Plot stacked bar chart
ggplot(stacked_data, aes(x = year, y = proportion, fill = category)) +
  geom_bar(stat = 'identity', position = 'stack') + # plot the stacked bar chart
  geom_text(aes(
    label = paste0(category,'\n',scales::percent(proportion, accuracy = 0.1))
    ), 
    colour = 'white', 
    size = 2.7,
    position = position_stack(vjust = 0.5)) + # add the proportion labels
  scale_fill_viridis_d(option = "D") +
  labs(title = 'Yearly News Proportion of Top 3 Categories and Others',
       x = 'Year', y = 'News Proportion',
       fill = 'News\nCategory', caption = 'Source: Kaggle Dataset (Misra, 2022)') # add title, annotations

# 2. Sentiment analysis of news headlines
# Step 1: Create a sentiment analysis dataframe
sentiment_news_data <- news_json_data_df %>% 
  select(headline, category, date, year_month, year)
# Step 2: Preprocessing the headlines
headlines_corpus <- Corpus(VectorSource(sentiment_news_data$headline))
headlines_corpus_cleaned <- tm_map(headlines_corpus, content_transformer(tolower))    # Convert to lowercase
headlines_corpus_cleaned <- tm_map(headlines_corpus_cleaned, removePunctuation)              # Remove punctuation
headlines_corpus_cleaned <- tm_map(headlines_corpus_cleaned, removeNumbers)                  # Remove numbers
headlines_corpus_cleaned <- tm_map(headlines_corpus_cleaned, removeWords, stopwords("en"))   # Remove common stopwords
headlines_corpus_cleaned <- tm_map(headlines_corpus_cleaned, stripWhitespace)                # Remove extra whitespace
headlines_corpus_cleaned <- tm_map(headlines_corpus_cleaned, lemmatize_strings) # Lemmatization
# Convert the cleaned corpus back into a character vector
sentiment_news_data$cleaned_headlines <- sapply(headlines_corpus_cleaned, as.character)
# Step 3: sentiment analysis
# Calculate sentiment scores for each cleaned headline
sentiment_news_data$syuzhet_sentiment_score <- get_sentiment(sentiment_news_data$cleaned_headlines, method = "syuzhet")

# 3. Treemap: the average sentiment scores of different categories
###### Use Syuzhet lexicon
### Option1: all categories
# Step 1: Create a dataframe for treemap: category, count, mean sentiment score
tree_map_data_all <- sentiment_news_data %>%
  group_by(category) %>%
  summarise(count=n(), 
            mean_sentiment_syuzhet = mean(syuzhet_sentiment_score, na.rm = TRUE))
tree_map_data_all <- tree_map_data_all %>%
  arrange(desc(mean_sentiment_syuzhet)) %>%
  mutate(category = factor(category, levels = category))
# Step 2: Plot the treemap
ggplot(tree_map_data_all, aes(
  area = count,           # Size of each box based on the count
  fill = mean_sentiment_syuzhet,       # Color by sentiment type
  label = paste(category, "\n", round(mean_sentiment_syuzhet, 2)))) + # Labels with category and sentiment
  geom_treemap(colour='black') +
  geom_treemap_text(fontface = "bold", colour = "white", place = "centre", grow = TRUE, reflow = TRUE) +
  scale_fill_gradient2(low = "red", mid = "gray", high = "green", midpoint = 0) + #Custom colors
  labs(title = "Sentiment Distribution Across News Categories (2012-2022)",
       subtitle = "Using Syuzhet lexicon\nThe area represents the count of news headlines",
       fill = "Sentiment",
       caption='Source: Kaggle dataset (Misra, 2022)'
)



# 4. Boxplot: the sentiment scores distribution of different categories
### Syuzhet lexicon
# All category
sentiment_news_data %>% 
  ggplot(aes(x=category, y=syuzhet_sentiment_score)) + 
  geom_boxplot(notch=TRUE, varwidth = TRUE, fill='plum') + 
  geom_hline(yintercept = 0, linetype = "dashed", color = "red", size = 0.3) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
  labs(
    title = 'Sentiment Score Distribution Across All Categories', 
    subtitle = 'Using Syuzhet lexicon\nThe box width represents the count of news headlines',
    x='News Category', 
    y='Sentiment Score (Syuzhet Lexicon)', 
    caption='Source: Kaggle Dataset (Misra, 2022)') 

# 5. The sentiment trend of politics news
# Step 1: select only the politics news
politics_news_data <- sentiment_news_data[sentiment_news_data$category == 'POLITICS', ]
politics_news_data <- politics_news_data %>% select(headline, category, year_month, syuzhet_sentiment_score)

# Scatter plot: trend of sentiment scores in politics news
scatter_data <- politics_news_data %>%
  group_by(year_month) %>%
  summarise(mean_sentiment = mean(syuzhet_sentiment_score), na.rm=TRUE)
scatter_data$time <- as.Date(paste0(scatter_data$year_month, "-01"), format = "%Y-%m-%d")

scatter_data %>%
  ggplot(aes(x = time, y = mean_sentiment)) + 
  geom_point() +
  geom_line() +
  geom_vline(xintercept = as.Date(c('2015-05-1', '2016-11-1', '2017-06-1', '2019-12-1','2020-11-1')), color = 'red', linetype = 'dashed') + 
  geom_vline(xintercept = as.Date(c('2016-11-1', '2020-11-1')), color = 'blue', linetype = 'dashed') + 
  geom_hline(yintercept = 0, color = 'grey', linetype = 'dashed') + 
  ggplot2::annotate("label", x = as.Date('2015-05-1'), 
                    y = max(scatter_data$mean_sentiment, na.rm = TRUE) + 1, 
                    label = "2015 UK\nGeneral Election", color = 'red', vjust = 1) +
  ggplot2::annotate("label", x = as.Date('2017-06-1'), 
                    y = max(scatter_data$mean_sentiment, na.rm = TRUE) + 1, 
                    label = "2017 UK\nGeneral Election", color = 'red', vjust = 1) +
  ggplot2::annotate("label", x = as.Date('2019-12-1'), 
                    y = max(scatter_data$mean_sentiment, na.rm = TRUE) + 1, 
                    label = "2019 UK\nGeneral Election", color = 'red', vjust = 1) +
  ggplot2::annotate("label", x = as.Date('2016-11-1'), 
                    y = max(scatter_data$mean_sentiment, na.rm = TRUE) + 1, 
                    label = "2016 US Election", color = 'blue', vjust = 30) +
  ggplot2::annotate("label", x = as.Date('2020-11-1'), 
           y = max(scatter_data$mean_sentiment, na.rm = TRUE) + 1, 
           label = "2020 US Election", color = 'blue', vjust = 30) +
  ggplot2::annotate("label", y = 0, 
                    x = as.Date('2022-3-1'), 
                    label = "Neutral", color = 'grey', hjust = 0) +
  theme(axis.text.x = element_text(angle = 0, hjust = 1)) + 
  geom_smooth(se = FALSE) +
  labs(
    title = 'Sentiment Trend of Politics News',
    subtitle = 'The blue line represents the fitted trend line, illustrating the overall decreasing sentiment scores in political news over time', 
    x = 'Year month', 
    y = 'Mean sentiment score of the month',
    caption = 'Source: Kaggle dataset (Misra, 2022)'
  )














