FACET - Flexible Artifact Correction and Evaluation Toolbox for concurrelty recorded EEG/fMRI data
==================================================================================================

FACET is a modular toolbox for the fast and flexible correction and
evaluation of imaging artefacts of concurrently recorded EEG datasets. FACET
is implemented in Matlab and relies on the EEGLAB data structure (Delorme &
Makeig 2004). The whole toolbox consists of a "Correction" and an
"Evaluation" part. Within the "Correction" framework a selection of various
algorithms for correcting imaging induced artefacts are provided: average
artefact subtraction (AAS) (Allen et al. 2000), PCA based (Niazy et al.
2005) and adaptive template approaches (van der Meer et al. 2010; Moosmann
et al. 2009).

Additionally, various pre- and post-processing steps are implemented like
volume onset detection, sub-sample alignment or OBS and ANC. All steps are
implemented in a modular fashion to allow flexible combinations of different
approaches. The "Evaluation" part of FACET allows to assess the quality of
the chosen correction approach and to compare different settings.

**Requirements**

FACET relies on the EEGLAB data structure (Delorme & Makeig 2004) available
at http://sccn.ucsd.edu/eeglab/. To run the example scripts, one also needs
to install the FASTR algorithm (Niazy et al. 2005) available as an EEGLAB
plugin at http://www.fmrib.ox.ac.uk/eeglab/fmribplugin.

**Documentation**

The Toolbox is extensively explained in the book `fMRI Artifact Correction
in EEG and EMG Data: Introducing FACET: A Flexible Artifact Correction and
Evaluation Toolbox for EEG/fMRI Data
<http://en.wikipedia.org/w/index.php?title=Special%3ABookSources&isbn=3659376078>`_
and in my diploma thesis doc/thesis.pdf. Please see src/README for more
information.

Additional documentation with sample scripts implementing the most common
algorithms can be found in Glaser et al. (2013).

**Citing the toolbox**

While FACET is free software provided under the GPL we would like to ask
those who use this software and find it useful to refer it as "FACET - a
flexible artifact correction and evaluation toolbox for concurrently
recorded EEG/fMRI data provided by the Medical University of Vienna,
Department of Neurology" and cite it as:

Glaser, J., Beisteiner, R., Bauer, H., & Fischmeister, F. P. S. (2013).
FACET - a "Flexible Artifact Correction and Evaluation Toolbox" for
concurrently recorded EEG/fMRI data. BMC neuroscience, 14(1), 138.
doi:10.1186/1471-2202-14-138, http://www.biomedcentral.com/1471-2202/14/138.

**License**

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version the terms of the GNU General Public License (GPL) to
provide powerful collaboration, review, and code management of possible
future extensions.

**References**


- Allen PJ, Josephs O, Turner R: A method for removing imaging artifact from
  continuous EEG recorded during functional MRI. NeuroImage 2000,
  12(2):230-239.

- Delorme A, Makeig S: EEGLAB: an open source toolbox for analysis of
  single-trial EEG dynamics including independent component analysis.
  JNeurosciMethods 2004, 134:9-21.

- Glaser, J., Beisteiner, R., Bauer, H., & Fischmeister, F. P. S. (2013).
  FACET - a "Flexible Artifact Correction and Evaluation Toolbox" for
  concurrently recorded EEG/fMRI data. BMC neuroscience, 14(1), 138.

- Niazy RK, Beckmann CF, Iannetti GD, Brady JM, Smith SM: Removal of FMRI
  environment artifacts from EEG data using optimal basis sets. NeuroImage
  2005, 28(3):720-737.

- Moosmann M, Schönfelder V, Specht K: Realignment parameter-informed
  artefact correction for simultaneous EEG-fMRI recordings. NeuroImage 2009,
  45(4):1144-1150.

- Van Der Meer JN, TijssenMAJ, Bour LJ, Rootselaar AFV, Nederveen AJ, van
  der Meer JN, van Rootselaar AFF: Robust EMG-fMRI artifact reduction for
  motion (FARM). Clin Neurophysiol Official J Int Fed Clin Neurophysiol
  2010, 121(5):766-776.
