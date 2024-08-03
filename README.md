[![Gem Version](https://badge.fury.io/rb/Almirah.svg)](https://badge.fury.io/rb/Almirah)

# Overview

[Almirah](https://almirah.site/) is an Application Lifecycle Management framework. The framework by itself is a set of processes (work instructions) and software components used for:

* Project Management
* Requirements Management
* Test Management
* Change Management

This repository contains the Almirah Ruby gem's source code, a framework software component.

# How to Start

## Installation

Install the Almirah Ruby gem with the following command:

```bash
gem install Almirah 
```

>Please note that the gem has a capital letter in the name. It is essential for installation.

## Project Creation

The easiest way of creating a project is to use the *create* command of the Almirah gem:

```bash
Almirah create your_project_name
```

This command will create a simple project example in the *your_project_name* folder.

## Project Processing

The primary purpose of the Almirah gem as part of the framework is to control traceability between specifications from one side and between specifications and test cases from another side. This is done by converting markdown files to HTML files. During this conversion, references are replaced with HTML hyperlinks. The conversion process also produces Traceability and Coverage matrices.

Process you project folder with the following command:

```bash
Almirah please your_project_name
```

If the process is successful, navigate to the *your_project_name/build* folder and open the *index.html* file in your browser.

## Test Runs

The project processing (please) command from the section above uses test cases located in the *your_project_name/tests/protocols* folder for test coverage analysis. By design, this folder stores non-executed test protocols (test cases).

By design, this folder stores non-executed test protocols (test cases). To run (execute) the tests, copy them into the *your_project_name/tests/runs/NNN* folder, where NN is a test run ID (for example, 001), and mark them with a pass or fail results.

To obtain a coverage matrix that corresponds to the exact test run, feel free to use the following option:

```bash
Almirah please your_project_name --run NNN
```

For the project example obtained with the *create* command, try the following:

```bash
Almirah please your_project_name --run 001
```

**or**

```bash
Almirah please your_project_name --run 010
```

If the process is successful, navigate to the *your_project_name/build* folder and open the *index.html* file in your browser.

## Folders Structure

Almirah gem has the right to expect the following folder structure:

```bash
project_root_directory
|
+-- specifications/
|  |
|  +-- SPA/   
|  |  |
|  |  +-- spa.md
|  |  |
|  |  +-- img/
|  |
|  +-- SPB   
|     |
|     +-- spb.md
|     |
|     +-- img/
| 
+-- tests/
   |  
   +-- protocols/
   |  |
   |  +-- tp-001/
   |  |  |
   |  |  +-- tp-001.md
   |  |  |
   |  |  +-- img/
   |  |
   |  +-- tp-002/
   |     |
   |     +-- tp-002.md
   |     |
   |     +-- img/
   |
   +-- runs/
      |
      +-- 001/
         |
         +-- tp-001/
         |  |
         |  +-- tp-001.md
         |  |
         |  +-- img/
         |
         +-- tp-002/
            |
            +-- tp-002.md
            |
            +-- img/
```
