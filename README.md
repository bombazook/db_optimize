# Appbooster ruby dev test tasks
https://gist.github.com/KELiON/949731e077656ce036fa6114e7b47d2d

# SQL
1. Start db container `docker-compose up -d db`
2. Run tests `docker-compose run test bundle exec rspec`
3. By default it will create 1M records for each table. You may modify row counts for test tables with ROW_COUNTS env variable: `ROW_COUNTS=100000 docker-compose run test bundle exec rspec`.
4. Next runs will use created test data. To rebuild db with new ROW_COUNTS use FORCE_REBUILD=true on next run:
`FORCE_REBUILD=true ROW_COUNTS=1000 docker-compose run test bundle exec rspec`

