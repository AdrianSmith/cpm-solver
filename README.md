# Critical Path Solver

The Critical Path Method is used in many project management applications. 

### References:
- https://hbr.org/1963/09/the-abcs-of-the-critical-path-method
- https://www.pmcalculators.com/how-to-calculate-the-critical-path/
- https://www.workamajig.com/blog/critical-path-method
- https://thedigitalprojectmanager.com/projects/pm-methodology/critical-path-method/

### Example Output
```text
+-----------------------------------------------------------------------------------------------------------------------------------------------------+
|                                                                    Program: Test                                                                    |
+-------+-------+----------+-------+----------+--------------+---------------+----------------+-------------+--------------+------------+-------------+
| Ref   | Name  | Duration | Slack | Critical | Dependencies | Planned_Start | Planned_Finish | Early_Start | Early_Finish | Late_Start | Late_Finish |
+-------+-------+----------+-------+----------+--------------+---------------+----------------+-------------+--------------+------------+-------------+
| Start | Start |    0     |   0   | true     |              | 2020-03-01    |                | 2020-03-01  | 2020-03-01   | 2020-03-01 | 2020-03-01  |
| A1000 | A     |    3     |   0   | true     | Start        |               |                | 2020-03-01  | 2020-03-04   | 2020-03-01 | 2020-03-04  |
| A1010 | B     |    4     |   2   | false    | A1000        |               |                | 2020-03-04  | 2020-03-08   | 2020-03-06 | 2020-03-10  |
| A1020 | C     |    6     |   0   | true     | A1000        |               |                | 2020-03-04  | 2020-03-10   | 2020-03-04 | 2020-03-10  |
| A1030 | D     |    6     |   2   | false    | A1010        |               |                | 2020-03-08  | 2020-03-14   | 2020-03-10 | 2020-03-16  |
| A1040 | E     |    4     |   2   | false    | A1010        |               |                | 2020-03-08  | 2020-03-12   | 2020-03-10 | 2020-03-14  |
| A1050 | F     |    4     |   0   | true     | A1020        |               |                | 2020-03-10  | 2020-03-14   | 2020-03-10 | 2020-03-14  |
| A1060 | G     |    6     |   2   | false    | A1030        |               |                | 2020-03-14  | 2020-03-20   | 2020-03-16 | 2020-03-22  |
| A1070 | H     |    8     |   0   | true     | A1040 A1050  |               |                | 2020-03-14  | 2020-03-22   | 2020-03-14 | 2020-03-22  |
| End   | End   |    0     |   0   | true     | A1070 A1060  |               |                | 2020-03-22  | 2020-03-22   | 2020-03-22 | 2020-03-22  |
+-------+-------+----------+-------+----------+--------------+---------------+----------------+-------------+--------------+------------+-------------+
```

![Schedule.pdf](https://github.com/user-attachments/files/17351623/Schedule.pdf)


## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cpm_solver. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/cpm_solver/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the CpmSolver project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/cpm_solver/blob/master/CODE_OF_CONDUCT.md).
