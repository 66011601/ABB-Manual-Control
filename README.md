# ABB-Manual-Control

A prototype project to control an ABB robot using Python via a custom FlexPendant simulation.

## Overview

This project consists of two main components:

1. **`send_position.py`** — A Python script to send joint positions via the terminal (CMD).
2. **`ModTCPJointMove.mod`** — A RAPID module to be uploaded into the ABB FlexPendant using RobotStudio.

---

## Files

### 1. `send_position.py`
Run this script from your terminal to send target joint positions to the ABB robot.

#### Requirements

Install the required Python modules using pip:

```bash
python3 -m pip install socket
python3 -m pip install ast
python3 -m pip install time
python3 -m pip install os
python3 -m pip install keyboard

