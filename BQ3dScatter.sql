--if exists (SELECT * FROM Export4Analysis.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Committer_RepoSize_LangCount') then
--  drop table Export4Analysis.Committer_RepoSize_LangCount;
--end if;

--create table Export4Analysis.Committer_RepoSize_LangCount
--(
--  repo_name string,
--  committerCount int64,
--  repoSize int64,
--  LangCount int64
--);

--insert Export4Analysis.Committer_RepoSize_LangCount(repoCount,currLang,matchLang)
  with committertable as 
  (
    select single_repo, count(distinct committer.name) as numcommitter
    from `bigquery-public-data.github_repos.commits`
    CROSS JOIN UNNEST(repo_name) AS single_repo
    group by single_repo
  ),
  langNsize as (
    SELECT repo_name AS repo_name,
    ARRAY_AGG(language.name) AS language_array,
    COUNT(distinct language.name) as lang_count,
    SUM(bytes) as repo_size
    FROM `bigquery-public-data.github_repos.languages`, unnest(language) as language
    group by repo_name
  )
  select langNsize.repo_name, lang_count, repo_size, numcommitter
  from committertable inner join langNsize ON committertable.single_repo=langNsize.repo_name;
 
