with filetypesperRepoCount as 
(
  select REGEXP_EXTRACT(path, r"\.([^\.]+)$") AS filetype, repo_name
  from `bigquery-public-data.github_repos.files`
  order by repo_name
), expandedRepos as (
  select single_repo, extract(YEAR from TIMESTAMP_SECONDS(author.time_sec)) as year
  from `bigquery-public-data.github_repos.commits` 
  CROSS JOIN UNNEST(repo_name) AS single_repo
  order by single_repo
)
select filetype, year as repoCreatedYear, count(*)
from filetypesperRepoCount join expandedRepos on single_repo = repo_name
group by filetype, repoCreatedYear
order by repoCreatedYear asc, count(*) desc
