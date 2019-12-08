declare languages array<string>;
declare currLang string;
declare currRepos array<string>;
declare matchLang string;
declare i INT64 default 1;
declare j INT64 default 1;
declare langCount INT64 default 0;
declare data array<string>;

IF EXISTS (SELECT * FROM Export4Analysis.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'langCorrHeatVal') then
  drop table Export4Analysis.langCorrHeatVal;
end if;

create table Export4Analysis.langCorrHeatVal
(
  repoCount int64,
  currLang string,
  matchLang string
);

set languages = array(select language.name
                      from `bigquery-public-data.github_repos.languages`, unnest(language) as language
                      group by language.name 
                      order by count(repo_name) desc
                      limit 20);

set langCount = array_length(languages);


loop
  set currLang = languages[ORDINAL(i)];
  set j = i+1;
  loop
    set matchLang = languages[ORDINAL(j)];
    insert Export4Analysis.langCorrHeatVal(repoCount,currLang,matchLang)
      with curr as(
        select repo_name, language.name as langname, language.bytes as langbytes
        from `bigquery-public-data.github_repos.languages`, unnest(language) as language
        where language.name = currLang
      ), match as (
        select repo_name, language.name as langname, language.bytes as langbytes
        from `bigquery-public-data.github_repos.languages`, unnest(language) as language
        where language.name = matchLang
      ),
      joined as (
        select curr.repo_name as repo_name, curr.langname as currl, match.langname as matchl
        from curr inner join match on curr.repo_name = match.repo_name
      )
      select count(repo_name),currl,matchl
      from joined
      group by currl, matchl;
    set j = j+1;
    if(j>langCount) then break; end if;
  end loop;
  set i = i+1;
  if(i>=langCount ) then break; end if;
end loop;


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
select currLang, array_agg(matchLang),array_agg(repoCount)
from orderedlang
group by currLang;
