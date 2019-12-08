PROJECT_ID = 'bigquerygittut'
from google.cloud import bigquery
bigquery_client = bigquery.Client(project=PROJECT_ID)
from google.cloud import storage
storage_client = storage.Client(project=PROJECT_ID)

## correlation

query1 = """
        select *
        from `bigquerygittut.Export4Analysis.committer_lang_size`
        """
# Set up the query
query_job1 = bigquery_client.query(query1)

# Make an API request  to run the query and return a pandas DataFrame
alllang = query_job1.to_dataframe()

# This import registers the 3D projection, but is otherwise unused.
from mpl_toolkits.mplot3d import Axes3D  # noqa: F401 unused import

import matplotlib.pyplot as plt
import numpy as np

fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')

n = 100

# For each set of style and range settings, plot n random points in the box
# defined by x in [23, 32], y in [0, 100], z in [zlow, zhigh].
for m, zlow, zhigh in [('o', -50, -25), ('^', -30, -5)]:
    xs = randrange(n, 23, 32)
    ys = randrange(n, 0, 100)
    zs = randrange(n, zlow, zhigh)
xs = alllang['repo_size']
ys = alllang['numcommitter']
zs = alllang['lang_count']
    
ax.scatter(xs, ys, zs, marker=m)
print(xs)
ax.set_xlabel('repo_size')
ax.set_ylabel('numcommitter')
ax.set_zlabel('lang_count')

plt.show()

## heatmap
query2 = """
        with currCount as (
          select currLang, count(currLang) as currSum
          from `bigquerygittut.Export4Analysis.langCorrHeatVal`
          group by currLang
          order by count(currLang) desc
        ), matchCount as (
          select matchLang, count(matchLang) as matchSum
          from `bigquerygittut.Export4Analysis.langCorrHeatVal`
          group by matchLang
          order by count(matchLang) desc
        ), joinedCount as (
        select currCount.currLang as currLang, matchCount.matchLang as matchLang, repoCount, currSum, matchSum
        from `bigquerygittut.Export4Analysis.langCorrHeatVal` 
          join currCount on currCount.currLang = `bigquerygittut.Export4Analysis.langCorrHeatVal`.currLang
          join matchCount on matchCount.matchLang = `bigquerygittut.Export4Analysis.langCorrHeatVal`.matchLang
        ), orderedlang as (
          select currLang, matchLang, repoCount, currSum, matchSum
          from joinedCount
          order by currSum desc, matchSum asc
        )
        select currLang, array_agg(matchLang) langindx,array_agg(repoCount) as numrepos
        from orderedlang
        group by currLang
        ;
        """
# Set up the query
query_job1 = bigquery_client.query(query2)

# Make an API request  to run the query and return a pandas DataFrame
alllang = query_job1.to_dataframe()

size = len(alllang['numrepos'])
print(size)
heatmapval = np.zeros((size,size))
counter = 0
for row in alllang['numrepos']:
    heatmapval[counter,counter:size]=np.divide(row,row[0])
    counter = counter + 1
    
import seaborn as sns # for data visualization
import matplotlib.pyplot as plt
plt.rcParams["figure.figsize"] = (10,10)
#corr = np.corrcoef(np.random.randn(10, 200))
#mask = np.zeros_like(corr)
#mask[np.triu_indices_from(mask)] = True
#print(corr)
#print(mask)
x_axis_labels = alllang.at[0,'langindx']
y_axis_labels = x_axis_labels

with sns.axes_style("white"):
    ax = sns.heatmap(heatmapval, vmax=max(heatmapval[0,0:size]), square=True, 
                    xticklabels=x_axis_labels, yticklabels=y_axis_labels, cmap="YlGnBu")
    plt.show()



