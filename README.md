# Critical Path Solver

*(This is a work in progress ATM)*

The Critical Path Method is used in many project management applications.

### Goals
- Solve the Critical Path Method with Activity on Node
- Generate a directed diagram as pdf file
- Generate a summary of the program
- Return a list of critical activities
- Support modelling of activities with the following relationships:
    - Start to Finish
    - Start to Start
    - Finish to Start
    - Finish to Finish
- Use as the basis for an API

### References:
- https://hbr.org/1963/09/the-abcs-of-the-critical-path-method
- https://www.pmcalculators.com/how-to-calculate-the-critical-path/

### Example Output
```text
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|                                                                            Program: HBR Program                                                                             |
+-----+-----------------------------------------------------+----------+-------+----------+--------------+------------+-------------+--------------+------------+-------------+
| Ref | Name                                                | Duration | Slack | Critical | Predecessors | Successors | Early_Start | Early_Finish | Late_Start | Late_Finish |
+-----+-----------------------------------------------------+----------+-------+----------+--------------+------------+-------------+--------------+------------+-------------+
| a   | Start                                               |    0     |   0   | true     |              | b          | 0           | 0            | 0          | 0           |
| b   | Excavate and pour footers                           |    4     |   0   | true     | a            | c          | 0           | 4            | 0          | 4           |
| c   | Pour concrete foundation                            |    2     |   0   | true     | b            | d f r      | 4           | 6            | 4          | 6           |
| d   | Erect wooden frame including rough roof             |    4     |   0   | true     | c            | e i j      | 6           | 10           | 6          | 10          |
| e   | Lay brickwork                                       |    6     |   8   | false    | d            | p          | 10          | 16           | 18         | 24          |
| f   | Install basement drains and plumbing                |    1     |   1   | false    | c            | g h        | 6           | 7            | 7          | 8           |
| g   | Pour basement floor                                 |    2     |   1   | false    | f            | j          | 7           | 9            | 8          | 10          |
| h   | Install rough plumbing                              |    3     |   4   | false    | f            | k          | 7           | 10           | 11         | 14          |
| i   | Install rough wiring                                |    2     |   2   | false    | d            | k          | 10          | 12           | 12         | 14          |
| j   | Install heating and ventilating                     |    4     |   0   | true     | d g          | k          | 10          | 14           | 10         | 14          |
| k   | Fasten plaster board and plaster (including drying) |    10    |   0   | true     | i j h        | l          | 14          | 24           | 14         | 24          |
| l   | Lay finish flooring                                 |    3     |   0   | true     | k            | m n o      | 24          | 27           | 24         | 27          |
| m   | Install kitchen fixtures                            |    1     |   1   | false    | l            | t          | 27          | 28           | 28         | 29          |
| n   | Install finish plumbing                             |    2     |   0   | true     | l            | t          | 27          | 29           | 27         | 29          |
| o   | Finish carpentry                                    |    3     |   2   | false    | l            | s          | 27          | 30           | 29         | 32          |
| p   | Finish roofing and flashing                         |    2     |   8   | false    | e            | q          | 16          | 18           | 24         | 26          |
| q   | Fasten gutters and downspouts                       |    1     |   8   | false    | p            | v          | 18          | 19           | 26         | 27          |
| r   | Lay storm drains for rain water                     |    1     |  20   | false    | c            | v          | 6           | 7            | 26         | 27          |
| s   | Sand and varnish flooring                           |    2     |   0   | true     | o t          | x          | 32          | 34           | 32         | 34          |
| t   | Paint                                               |    3     |   0   | true     | m n          | s u        | 29          | 32           | 29         | 32          |
| u   | Finish electrical work                              |    1     |   1   | false    | t            | x          | 32          | 33           | 33         | 34          |
| v   | Finish grading                                      |    2     |   8   | false    | q r          | w          | 19          | 21           | 27         | 29          |
| w   | Pour walks and complete landscaping                 |    5     |   8   | false    | v            | x          | 21          | 26           | 29         | 34          |
| x   | Finish                                              |    0     |   0   | true     | s u w        |            | 34          | 34           | 34         | 34          |
+-----+-----------------------------------------------------+----------+-------+----------+--------------+------------+-------------+--------------+------------+-------------+
```

![HBR Program.pdf](https://github.com/user-attachments/files/17466754/HBR.Program.pdf)

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
