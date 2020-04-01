# JUNGFRAU X-ray Detector Data Acquisition Action

**General action description**

* SNAP Action, that allows to acquire X-ray images with the JUNGFRAU X-ray detector from the Paul Scherrer Institut (Villigen, Switzerland)
* Action is doing the following tasks:
** Receiving UDP/IP packets sent from the detector
** Applying gain and pedestal corrections
** Compose full images from the frames

* Broader decription of the task is presented in publication: 
** Leonarski et al. "JUNGFRAU detector for brighter x-ray sources: Solutions for IT and data science challenges in macromolecular crystallography", Structural Dynamics 2020 (https://doi.org/10.1063/1.5143480)

* In the current version single FPGA Receiver is expected to handle detectors up to 2 Mpixel in size (80 GBit/s)

**Hardware requirements**
* IC 922 or AC 922 server from IBM
* Alpha Data 9H3 FPGA board(s)
* Jungfrau X-ray detector
* 100 Gbit/s switch between the detector and server to merge multiple 10 Gbit/s links into a single 100 Gbit/s link
