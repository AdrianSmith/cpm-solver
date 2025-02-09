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

### Solvers
- [x] Critical-Path Method
- [x] Topological Sorting
- [x] Dijkstra's Algorithm
- [x] Floyd-Warshall Algorithm

### Current Performance
- Critical-Path Method: O(V + E)
- Topological Sorting: O(V + E)
- Dijkstra's Algorithm: O((V + E) log V)
- Bellman-Ford Algorithm: O(VE)
- Floyd-Warshall Algorithm: O(V^3)

```
+----------------------------------------------------+
| Performance Results (250 activities, 5 iterations) |
+----------------+-----------+-----------+-----------+
| Solver         | Avg (ms)  | Min (ms)  | Max (ms)  |
+----------------+-----------+-----------+-----------+
| Critical-Path  | 0.61      | 0.38      | 1.37      |
| Bellman-Ford   | 84.2      | 83.38     | 85.39     |
| Floyd-Warshall | 2566.75   | 2536.2    | 2640.7    |
| Topological    | 0.65      | 0.63      | 0.7       |
| Dijkstra       | 6.34      | 6.18      | 6.46      |
+----------------+-----------+-----------+-----------+

+----------------------------------------------------+
| Performance Comparison (relative to Critical-Path) |
+--------------------------+-------------------------+
| Solver                   | Relative Speed          |
+--------------------------+-------------------------+
| Bellman-Ford             | 138.31x slower          |
| Floyd-Warshall           | 4216.08x slower         |
| Topological              | 1.07x slower            |
| Dijkstra                 | 10.41x slower           |
+--------------------------+-------------------------+
```

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

![HBR Program.pdf](https://github.com/user-attachments/files/17474682/HBR.Program.pdf)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cpm_solver. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/cpm_solver/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
