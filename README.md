# RoboSim Generator Plugin Template

This is a template that can be used to start new generator plugins for RoboSim.

In order to start a new plugin, create a new repository based on this one using the "use this template" button (at the top-right corner of the main page of the repository).

After creating a copy of the repository, make sure you change all references of prism to your target language (e.g., uppaal), and test compilation with `mvn clean install`.

Necessary changes:
- rename folders
- update pom.xml to reflect new names (possibly versions of eclipse and xtext)
- in the feature project, update both .project pom.xml and feature.xml
- in the update project, update .project, pom.xml and category.xml
- in the remaining project, update the following files:
  - pom.xml and .project as above
  - plugin.xml the first extension point "robosim.generator". This should be updated to point to the actual generator class and to reflect the correct code generation folder (e.g., csp-gen). The generator will be called automatically be the RoboSim editor as long as this extension point is set up correctly.
    - in addition, you can update the commands, handlers, bindings and menus that create button to call the generator and analysis tools (e.g, FDR) from Eclipse.
  - in "src/circus/robocalc/robosim/generator/prism/sim" (change prism to appropriate name), the file SimGenerator.xtend is the base of the code generator.
    - it extends the class AbstractRoboSimGenerator that is required by the RoboSim editor to implement automatic generation;
    - the method getID() should provide a string that uniquely identifies the generator;
    - the method doGenerate(...) starts the generation; the parameters are provided by RoboSim editor:
      - resource contains the RoboSim model; the RSPackage can be obtained by looking for the first component of "resource.contents".
      - fsa supports the creation of new files; it takes the name of the file, the identifier (getID()) and the content of the file.
      - the context is not often used.
