# Modular System State-Space

This project builds a modular small-signal state-space model of an electrical power system. The main workflow first computes an AC power-flow operating point, then builds and linearizes the dynamic models of the converters, transmission line, and grid equivalent. The resulting models are interconnected and used for modal stability analysis.

## Requirements

- MATLAB
- [MATPOWER](https://matpower.org/) installed separately and available on the MATLAB path
- Symbolic Math Toolbox
- Control System Toolbox

The repository does not currently enforce a minimum MATLAB or MATPOWER version. The implementation uses symbolic Jacobians, `ss` models, `connect`, `sumblk`, and `uifigure`.

## Repository Structure

```text
.
|-- main.m                         Main state-space workflow
|-- power_flow_DC.m                Standalone DC/AC power-flow example
|-- data/
|   |-- parameters.csv             System, converter, line, and grid parameters
|   `-- netlist.csv                Component connectivity and operating modes
|-- lib/
|   |-- Setup/
|   |   |-- loadParameters.m       Loads CSV data and derives base quantities
|   |   |-- DC_Cap.m               Calculates DC-link capacitance and voltage
|   |   `-- thevenin.m              Calculates the grid Thevenin equivalent
|   |-- PowerFlow/
|   |   |-- loadNetlist.m           Reads the connectivity table
|   |   |-- powerflow.m             Builds and solves the MATPOWER case
|   |   |-- PF_results.m            Extracts operating-point values
|   |   |-- OP_Converters.m         Converts converter operating points to pu
|   |   |-- OP_Line.m               Converts line operating points to pu
|   |   `-- OP_Grids.m               Converts grid operating points to pu
|   `-- State_Space/
|       |-- stability_analysis.m    Eigenvalue and participation-factor analysis
|       `-- Classes/
|           |-- Converter_GFL.m      Grid-following converter model
|           |-- Line.m               PI-section line model
|           `-- Grid.m               Grid Thevenin RL model
|-- DESCRIPTION.md                  Short project description
`-- LICENSE                         MIT license
```

## Input Data

The model is configured through two CSV files in [`data/`](data/):

- [`parameters.csv`](data/parameters.csv) contains base quantities, setpoints, electrical parameters, controller gains, and grid strength data.
- [`netlist.csv`](data/netlist.csv) defines component IDs, component parameters, and the `From`/`To` bus connections. A connection to bus `0` represents a shunt-connected source or element.

The current example contains two converters, one line, and one grid equivalent. Converter 1 is used in `PQ` mode, converter 2 in `PV` mode, and the grid is connected as a slack source according to the netlist.

## Main Workflow

The execution path in [`main.m`](main.m) consists of the following steps.

### 1. Load parameters and the netlist

`loadParameters` reads the parameter table and creates the `parameters` structure. It also calculates system base quantities such as angular frequency, base impedance, base inductance, and base capacitance. Converter, line, and grid-specific derived quantities are stored in the corresponding structure arrays.

`loadNetlist` reads the connectivity table into a MATLAB table.

### 2. Solve the AC power flow

`powerflow(parameters, netlist)` builds a MATPOWER case from the netlist:

- buses are created from the highest non-zero bus number in the netlist;
- `PQ`, `PV`, and `Slack` source entries become MATPOWER bus or generator definitions;
- converter `R_vsc2` entries become series RL branches;
- line `R_line` entries become series RL branches;
- grid `R_grid` entries become the grid Thevenin RL branch;
- line capacitor entries are added as bus shunts, split between the two line terminals.

All electrical quantities are converted to the system base before the MATPOWER case is solved. MATPOWER returns bus voltages and angles, generator powers, and branch power flows.

### 3. Extract and convert operating points

`PF_results` extracts the operating-point values for each converter, line, and grid from the MATPOWER solution. The `OP_*` functions then convert these values into the per-unit quantities required by the dynamic models, including:

- converter currents, filter voltages, controller states, and references;
- line terminal voltages and currents for the PI section;
- grid source voltage, current, and point-of-connection voltage.

These values are used as the equilibrium around which the dynamic equations are linearized.

### 4. Build symbolic component models

Each class exposes a `build()` method. It defines symbolic differential equations, algebraic equations, inputs, outputs, and parameters.

- `Converter_GFL` includes the converter filters, DC-link dynamics, outer active/reactive or voltage control loops, inner current controllers, PLL, and frame transformations.
- `Line` represents a series RL branch with shunt capacitance at both terminals.
- `Grid` represents the Thevenin equivalent as a dynamic RL branch.

For the converter, the algebraic equations are eliminated symbolically. The resulting state-space Jacobians are obtained from the differential and algebraic equations.

### 5. Evaluate the linearized models

The `evaluate()` method substitutes the operating point and numerical parameters into the symbolic Jacobians and creates MATLAB `ss` objects. It also calculates differential and algebraic equilibrium residuals, which indicate how closely the supplied operating point satisfies the model equations.

Each model receives unique state names based on its component ID. These names are later used by the system-level interconnection and stability analysis.

### 6. Interconnect the subsystems

`main.m` assigns signal names to the inputs and outputs of each `ss` model. MATLAB `connect()` then joins signals with matching names.

The interconnection represents the following signal flow:

```text
Converter 1 -> Line -> Grid
			  ^
			  |
		  Converter 2
```

The two `sumblk` equations implement the current balance at the node shared by the line, grid, and converter 2:

```matlab
Ig_d = Ig1_d - Ic2_d
Ig_q = Ig1_q - Ic2_q
```

The external inputs currently exposed by the connected model are:

- `Pref`, `Vdc_ref`, `Q_ref`: converter 1 references;
- `Pref2`, `Vdc_ref2`, `Vpoc_ref2`: converter 2 references;
- `V0_1_d`, `V0_1_q`: grid voltage inputs.

The selected outputs include converter currents, grid current, and the line terminal voltages.

### 7. Perform modal stability analysis

`stability_analysis(SYS)` computes the eigenvalues of the assembled state matrix, damping ratios, modal frequencies, and participation factors. It produces:

- a pole-zero map with the selected critical mode;
- a table of eigenvalues and modal quantities in the MATLAB command window;
- a participation-factor table for the critical mode;
- a GUI table showing the participation factors of all states and modes.

The critical mode is selected as the stable mode with the lowest damping ratio. If no stable modes exist, the first non-stable mode is selected.

## Running the Main Workflow

From the repository root, make the library and data folders available on the MATLAB path before calling `main`:

```matlab
addpath(genpath('lib'));
addpath('data');
main
```

MATPOWER must already be installed and available on the MATLAB path. The current `main.m` expects `parameters.csv` and `netlist.csv` to be resolvable from the MATLAB path; adding `data/` as shown above is therefore required unless the files are copied or the MATLAB path is configured differently.

## Standalone DC Power-Flow Example

[`power_flow_DC.m`](power_flow_DC.m) is separate from the main modular state-space workflow. It:

1. solves an AC power flow for the first AC area;
2. solves a three-node DC network with `fsolve`;
3. uses the resulting DC powers to define two additional AC power-flow cases;
4. stores the resulting AC and DC operating points in the `iniz` structure.

It is an exploratory example and is not called by [`main.m`](main.m).

## License

This project is distributed under the MIT License. See [`LICENSE`](LICENSE).
