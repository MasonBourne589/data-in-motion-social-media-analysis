import pandas as pd
from pathlib import Path

# Point to your Excel file (use the exact file name you have)
file_path = Path(__file__).resolve().parents[1] / "data" / "youtube_data.xlsx"

print("Looking for file at:", file_path)
print("File exists?", file_path.exists())

# Open the workbook and list sheets
xls = pd.ExcelFile(file_path)
print("\nSheets found in workbook:")
print(xls.sheet_names)

# Load the main sheet into df
df = pd.read_excel(file_path, sheet_name="Table data")

print("\nDataset shape (rows, cols):", df.shape)
print("\nColumns:", list(df.columns))
print("\nFirst 5 rows:")
print(df.head())

# Cleaning Step 1: keep only real video rows (the Total row has no Video title)
df_videos = df[df["Video title"].notna()].copy()

print("\nRows before:", len(df))
print("Rows after (videos only):", len(df_videos))

# Quick sanity check: the first few titles should be real video titles now
print("\nFirst 3 video titles:")
print(df_videos["Video title"].head(3).to_string(index=False))

# Cleaning Step 2: convert publish time from text → datetime
df_videos["Video publish time"] = pd.to_datetime(df_videos["Video publish time"], errors="coerce")

print("\nPublish time dtype:", df_videos["Video publish time"].dtype)
print("Missing publish times:", df_videos["Video publish time"].isna().sum())

print("\nFirst 3 publish times:")
print(df_videos["Video publish time"].head(3).to_string(index=False))

# KPI calculations
total_views = df_videos["Views"].sum()
total_subscribers = df_videos["Subscribers"].sum()
total_impressions = df_videos["Impressions"].sum()
total_revenue = df_videos["Estimated revenue (USD)"].sum()
avg_ctr = df_videos["Impressions click-through rate (%)"].mean()

print("\n----- Channel KPIs -----")
print("Total Views:", total_views)
print("Total Subscribers:", total_subscribers)
print("Total Impressions:", total_impressions)
print("Total Revenue (USD):", round(total_revenue, 2))
print("Average CTR (%):", round(avg_ctr, 2))


# Top videos by Views
top_views = df_videos.sort_values("Views", ascending=False)[
    ["Video title", "Views"]
].head(5)

print("\nTop 5 Videos by Views:")
print(top_views)


# Top videos by Subscribers
top_subs = df_videos.sort_values("Subscribers", ascending=False)[
    ["Video title", "Subscribers"]
].head(5)

print("\nTop 5 Videos by Subscribers:")
print(top_subs)


# Top videos by Revenue
top_revenue = df_videos.sort_values("Estimated revenue (USD)", ascending=False)[
    ["Video title", "Estimated revenue (USD)"]
].head(5)

print("\nTop 5 Videos by Revenue:")
print(top_revenue)

# Create a month column from publish date
df_videos["publish_month"] = df_videos["Video publish time"].dt.to_period("M")

# Aggregate views by month
monthly_views = (
    df_videos.groupby("publish_month")["Views"]
    .sum()
    .reset_index()
)

print("\nMonthly Views:")
print(monthly_views)

# Create output folder path
output_path = Path(__file__).resolve().parents[1] / "outputs"

output_path.mkdir(exist_ok=True)

# Export cleaned video dataset
df_videos.to_csv(output_path / "youtube_cleaned_videos.csv", index=False)

# Export monthly views
monthly_views.to_csv(output_path / "youtube_monthly_views.csv", index=False)

print("\nDatasets exported to outputs folder.")

# Subscriber conversion rate
df_videos["subscriber_conversion_rate"] = (
    df_videos["Subscribers"] / df_videos["Views"]
)

# Convert to percentage and round
df_videos["subscriber_conversion_rate_pct"] = (
    df_videos["subscriber_conversion_rate"] * 100
).round(2)

# Top converting videos
top_conversion = df_videos.sort_values(
    "subscriber_conversion_rate_pct", ascending=False
)[["Video title", "Views", "Subscribers", "subscriber_conversion_rate_pct"]].head(5)

print("\nTop 5 Videos by Subscriber Conversion Rate (%):")
print(top_conversion)

from collections import Counter

# Get top 20 videos by views
top_videos = df_videos.sort_values("Views", ascending=False).head(20)

# Combine all titles into one string
titles = " ".join(top_videos["Video title"].dropna())

# Convert to lowercase
titles = titles.lower()

# Split titles into words
words = titles.split()

# Count word frequency
word_counts = Counter(words)

print("\nMost Common Words in Top Video Titles:")
print(word_counts.most_common(15))

import re
from collections import Counter

stopwords = {
    "the","a","an","and","or","to","of","in","on","for","with","is","are","was","were",
    "you","your","i","im","i’d","its","it","this","that","these","those","now","more"
}

top_videos = df_videos.sort_values("Views", ascending=False).head(20)

# Clean titles: lowercase + remove punctuation
cleaned_words = []
for title in top_videos["Video title"].dropna():
    title = title.lower()
    title = re.sub(r"[^a-z0-9\s]", "", title)  # keep letters/numbers/spaces only
    words = title.split()
    words = [w for w in words if w not in stopwords and len(w) > 2]
    cleaned_words.extend(words)

word_counts_clean = Counter(cleaned_words)

print("\nMost Common CLEAN Words in Top Video Titles:")
print(word_counts_clean.most_common(15))

df_videos.to_csv("clean_youtube_videos.csv", index=False)
monthly_views.to_csv("youtube_monthly_views.csv", index=False)

print("\nClean datasets exported.")

# Monthly views growth chart
import matplotlib.pyplot as plt
from pathlib import Path

# Create outputs folder
output_dir = Path(__file__).resolve().parents[1] / "outputs"
output_dir.mkdir(exist_ok=True)

plt.figure(figsize=(10,5))

plt.plot(
    monthly_views["publish_month"].astype(str),
    monthly_views["Views"],
    marker="o",
    linewidth=2
)

plt.xticks(rotation=45)
plt.title("YouTube Monthly Views Growth", fontsize=14)
plt.xlabel("Month")
plt.ylabel("Views")

# Correlation analysis between performance metrics

metrics = df_videos[[
    "Views",
    "Impressions",
    "Impressions click-through rate (%)",
    "Watch time (hours)",
    "Subscribers",
    "Estimated revenue (USD)"
]]

correlation_matrix = metrics.corr()

print("\nCorrelation Matrix:")
print(correlation_matrix)

import seaborn as sns
import matplotlib.pyplot as plt

plt.figure(figsize=(8,6))

sns.heatmap(
    correlation_matrix,
    annot=True,
    cmap="coolwarm",
    fmt=".2f"
)

plt.title("YouTube Performance Metric Correlation")
plt.tight_layout()

plt.savefig(output_dir / "youtube_corr_heatmap.png", dpi=200)

plt.show()