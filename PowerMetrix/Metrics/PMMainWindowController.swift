//
//  PMMainWindowController.swift
//  PowerMetrix
//
//  Created by hany on 30/10/21.
//

import Cocoa

// POWERMETRIX MAIN WINDOW CONTROLLER

class PMMainWindowController: NSWindowController, NSWindowDelegate {
    
    @IBOutlet var aboutWindow: NSWindow!
    @IBOutlet weak var label_version: NSTextField!
    @IBOutlet weak var cpu_icon: NSImageView!
    @IBOutlet weak var cpu_name_label: NSTextField!
    
    
    @IBOutlet weak var ring_ecpu: NSView!
    @IBOutlet weak var label_ecpu: NSTextField!
    @IBOutlet weak var ring_pcpu: NSView!
    @IBOutlet weak var label_pcpu: NSTextField!
    @IBOutlet weak var ring_gpu: NSView!
    @IBOutlet weak var label_gpu: NSTextField!
    @IBOutlet weak var ring_media: NSView!
    @IBOutlet weak var label_media: NSTextField!
    @IBOutlet weak var label_totalbw: NSTextField!
    
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.level = NSWindow.Level.modalPanel
        self.label_version.stringValue = "version \(powermetrixFullVersion())"
        self.cpu_icon.image = cpu_image()
        self.cpu_name_label.stringValue = cpu_name.uppercased()
        self.updateGUI()
    }
    
    
    
    
    // MARK: UPDATE GUI
    
    func updateGUI() {
        self.drawPackageEnergyGraph()
    }
    
    
    
    
    // MARK: PACKAGE ENERGY
    
    @IBOutlet weak var view_packageEnergy: NSView!
    var max_packageEnergy : Double = 0 {
        didSet {
            self.label_maxPackageEnergy.stringValue = "\(Int(max_packageEnergy))"
        }
    }
    
    
    @IBOutlet weak var label_maxPackageEnergy: NSTextField!
    @IBOutlet weak var label_currentPackageEnergy: NSTextField!
    
    func drawPackageEnergyGraph() {
        if self.window!.isVisible {
            
            // CURRENT VALUES
            
            var max_bw : Double = 70 // M1
            if cpu_name == "Apple M2" {
                max_bw = 100
            } else if cpu_name == "Apple M1 Pro" {
                max_bw = 200
            } else if cpu_name == "Apple M1 Max" {
                max_bw = 400
            } else if cpu_name == "Apple M1 Ultra" {
                max_bw = 800
            }
            
            if let metrix = metrics.last {
                
                // ENERGY
                
                let processor = metrix["processor"] as? [String:AnyObject]
                let value = ((Double(truncating: processor?["package_energy"] as? NSNumber ?? 0) / 1000).rounded(toPlaces: 1))
                self.label_currentPackageEnergy.stringValue = "\(value) W"
                
                // BANDWIDTH
                
                let bandwidth = metrix["bandwidth_counters"] as! [[String:AnyObject]]
                // build main bandwidth dictionary
                var bandwidthdict = [String:AnyObject]()
                for dict in bandwidth {
                    bandwidthdict[dict["name"] as! String] = dict["value"]
                }
                
                // number formatter
                let formatter = NumberFormatter()
                formatter.numberStyle = NumberFormatter.Style.decimal
                formatter.roundingMode = NumberFormatter.RoundingMode.halfUp
                formatter.maximumFractionDigits = 1
                let formatter2 = NumberFormatter()
                formatter2.numberStyle = NumberFormatter.Style.decimal
                formatter2.roundingMode = NumberFormatter.RoundingMode.halfUp
                formatter2.maximumFractionDigits = 2
                
                // rings shared frame
                let frame = NSRect(x: 0,
                                   y: 0,
                                   width: 50,
                                   height:50)
                
                // e-cpu
                let ecpu_dcs_rd = ((Double(truncating: bandwidthdict["ECPU DCS RD"] as? NSNumber ?? 0) / 1000000000))
                let ecpu_dcs_wr = ((Double(truncating: bandwidthdict["ECPU DCS WR"] as? NSNumber ?? 0) / 1000000000))
                let ecpu = ecpu_dcs_rd + ecpu_dcs_wr
                self.label_ecpu.stringValue = "\(String(describing: formatter.string(from: NSNumber(value: ecpu)) ?? "0")) GB/s"
                let ecpu_ring = PMRing(frame: frame,
                                  name: "ECPU",
                                  max: max_bw,
                                  value: Double(ecpu),
                                  color:NSColor.systemOrange)
                self.ring_ecpu.subviews.removeAll()
                self.ring_ecpu.addSubview(ecpu_ring)
                
                
                // p-cpu
                let pcpu0_dcs_rd = ((Double(truncating: bandwidthdict["PCPU0 DCS RD"] as? NSNumber ?? 0) / 1000000000))
                let pcpu0_dcs_wr = ((Double(truncating: bandwidthdict["PCPU0 DCS WR"] as? NSNumber ?? 0) / 1000000000))
                let pcpu1_dcs_rd = ((Double(truncating: bandwidthdict["PCPU1 DCS RD"] as? NSNumber ?? 0) / 1000000000))
                let pcpu1_dcs_wr = ((Double(truncating: bandwidthdict["PCPU1 DCS WR"] as? NSNumber ?? 0) / 1000000000))
                let pcpu_dcs_rd = ((Double(truncating: bandwidthdict["PCPU DCS RD"] as? NSNumber ?? 0) / 1000000000))
                let pcpu_dcs_wr = ((Double(truncating: bandwidthdict["PCPU DCS WR"] as? NSNumber ?? 0) / 1000000000))
                let pcpu = pcpu0_dcs_rd + pcpu0_dcs_wr + pcpu1_dcs_rd + pcpu1_dcs_wr + pcpu_dcs_rd + pcpu_dcs_wr
                self.label_pcpu.stringValue = "\(String(describing: formatter.string(from: NSNumber(value: pcpu)) ?? "0")) GB/s"
                let pcpu_ring = PMRing(frame: frame,
                                  name: "PCPU",
                                  max: max_bw,
                                  value: Double(pcpu),
                                  color:NSColor.systemYellow)
                self.ring_pcpu.subviews.removeAll()
                self.ring_pcpu.addSubview(pcpu_ring)
                
                
                // gpu
                let gpu_dcs_rd = ((Double(truncating: bandwidthdict["GFX DCS RD"] as? NSNumber ?? 0) / 1000000000))
                let gpu_dcs_wr = ((Double(truncating: bandwidthdict["GFX DCS WR"] as? NSNumber ?? 0) / 1000000000))
                let gpu = gpu_dcs_rd + gpu_dcs_wr
                self.label_gpu.stringValue = "\(String(describing: formatter.string(from: NSNumber(value: gpu)) ?? "0")) GB/s"
                let gpu_ring = PMRing(frame: frame,
                                  name: "GPU",
                                  max: 100, //max_bw,
                                  value: Double(gpu),
                                  color:NSColor.systemPurple)
                self.ring_gpu.subviews.removeAll()
                self.ring_gpu.addSubview(gpu_ring)
                
                
                // media
                let isp_dcs_rd = ((Double(truncating: bandwidthdict["ISP DCS RD"] as? NSNumber ?? 0) / 1000000000))
                let isp_dcs_wr = ((Double(truncating: bandwidthdict["ISP DCS WR"] as? NSNumber ?? 0) / 1000000000))
                let strm_dcs_rd = ((Double(truncating: bandwidthdict["STRM CODEC DCS RD"] as? NSNumber ?? 0) / 1000000000))
                let strm_dcs_wr = ((Double(truncating: bandwidthdict["STRM CODEC DCS WR"] as? NSNumber ?? 0) / 1000000000))
                let prores_dcs_rd = ((Double(truncating: bandwidthdict["PRORES DCS RD"] as? NSNumber ?? 0) / 1000000000))
                let prores_dcs_wr = ((Double(truncating: bandwidthdict["PRORES DCS WR"] as? NSNumber ?? 0) / 1000000000))
                let vdec_dcs_rd = ((Double(truncating: bandwidthdict["VDEC DCS RD"] as? NSNumber ?? 0) / 1000000000))
                let vdec_dcs_wr = ((Double(truncating: bandwidthdict["VDEC DCS WR"] as? NSNumber ?? 0) / 1000000000))
                let venc_dcs_rd = ((Double(truncating: bandwidthdict["VENC DCS RD"] as? NSNumber ?? 0) / 1000000000))
                let venc_dcs_wr = ((Double(truncating: bandwidthdict["VENC DCS WR"] as? NSNumber ?? 0) / 1000000000))
                let jpg_dcs_rd = ((Double(truncating: bandwidthdict["JPG DCS RD"] as? NSNumber ?? 0) / 1000000000))
                let jpg_dcs_wr = ((Double(truncating: bandwidthdict["JPG DCS WR"] as? NSNumber ?? 0) / 1000000000))
                let media = isp_dcs_rd + isp_dcs_wr + strm_dcs_rd + strm_dcs_wr + prores_dcs_rd + prores_dcs_wr + vdec_dcs_rd + vdec_dcs_wr + venc_dcs_rd + venc_dcs_wr + jpg_dcs_rd + jpg_dcs_wr
                self.label_media.stringValue = "\(String(describing: formatter.string(from: NSNumber(value: media)) ?? "0")) GB/s"
                let media_ring = PMRing(frame: frame,
                                  name: "MEDIA",
                                  max: 100, //max_bw,
                                  value: Double(media),
                                  color:NSColor.systemBlue)
                self.ring_media.subviews.removeAll()
                self.ring_media.addSubview(media_ring)
                
                
                // total bandwidth
                let total_bw = ecpu + pcpu + gpu + media
                self.label_totalbw.stringValue = "\(String(describing: formatter2.string(from: NSNumber(value: total_bw)) ?? "0")) GB/s"
                
            }
            
            
            
            // ENERGY HISTORY GRAPH
            
            // energy data
            var arrayPackage = [Double]()
            var arrayCPU = [Double]()
            var arrayGPU = [Double]()
            var arrayDRAM = [Double]()
            var arrayANE = [Double]()
            
            
            // populate arrays
            for metrix in metrics {
                
                // PACKAGE energy
                let processor = metrix["processor"] as? [String:AnyObject]
                let package_energy = ((Double(truncating: processor?["package_energy"] as? NSNumber ?? 0) / 1000).rounded(toPlaces: 1))
                arrayPackage.append(package_energy)
                
                // CPU energy
                let cpu_cpu_energy = ((Double(truncating: processor?["cpu_energy"] as? NSNumber ?? 0) / 1000).rounded(toPlaces: 1))
                arrayCPU.append(cpu_cpu_energy)
                
                // GPU energy
                let gpu = metrix["gpu"] as? [String:AnyObject]
                let gpu_gpu_energy = ((Double(truncating: gpu?["gpu_energy"] as? NSNumber ?? 0) / 1000).rounded(toPlaces: 1))
                arrayGPU.append(gpu_gpu_energy)
                
                // DRAM energy
                let cpu_dram_energy = ((Double(truncating: processor?["dram_energy"] as? NSNumber ?? 0) / 1000).rounded(toPlaces: 1))
                arrayDRAM.append(cpu_dram_energy)
                
                // ANE energy
                let cpu_ane_energy = ((Double(truncating: processor?["ane_energy"] as? NSNumber ?? 0) / 1000).rounded(toPlaces: 1))
                arrayANE.append(cpu_ane_energy)
            }
            
            
            // set automatic graph scale
            if let package_max = arrayPackage.max() {
                if package_max <= 1 {
                    self.max_packageEnergy = 1
                } else if package_max > 1 && package_max <= 2 {
                    self.max_packageEnergy = 2
                } else if package_max > 2 && package_max <= 5 {
                    self.max_packageEnergy = 5
                } else if package_max > 5 && package_max <= 10 {
                    self.max_packageEnergy = 10
                } else if package_max > 10 && package_max <= 20 {
                    self.max_packageEnergy = 20
                } else if package_max > 20 && package_max <= 30 {
                    self.max_packageEnergy = 30
                } else if package_max > 30 && package_max <= 40 {
                    self.max_packageEnergy = 40
                } else if package_max > 40 && package_max <= 50 {
                    self.max_packageEnergy = 50
                } else if package_max > 50 && package_max <= 75 {
                    self.max_packageEnergy = 75
                } else if package_max > 75 && package_max <= 100 {
                    self.max_packageEnergy = 100
                } else {
                    self.max_packageEnergy = 150
                }
            }
            
            
            // graphs
            let frame = NSRect(x: 0,
                               y: 0,
                               width: self.view_packageEnergy.frame.width,
                               height:self.view_packageEnergy.frame.height)
            
            let graph_package =  PMGraph(frame: frame,
                                 name: "Package Energy",
                                 array: arrayPackage,
                                 color: .systemRed)
            
            let graph_cpu =      PMGraph(frame: frame,
                                 name: "CPU Energy",
                                 array: arrayCPU,
                                 color: .systemYellow)
            
            let graph_gpu =      PMGraph(frame: frame,
                                 name: "GPU Energy",
                                 array: arrayGPU,
                                 color: .systemPurple)
            
            let graph_dram =     PMGraph(frame: frame,
                                 name: "DRAM Energy",
                                 array: arrayDRAM,
                                 color: .systemBlue)
            
            let graph_ane =      PMGraph(frame: frame,
                                 name: "ANE Energy",
                                 array: arrayANE,
                                 color: .systemGreen)
            
            // draw history gui
            self.view_packageEnergy.subviews.removeAll()
            self.view_packageEnergy.addSubview(graph_package)
            self.view_packageEnergy.addSubview(graph_cpu)
            self.view_packageEnergy.addSubview(graph_ane)
            self.view_packageEnergy.addSubview(graph_gpu)
            self.view_packageEnergy.addSubview(graph_dram)
        }
    }
    
    
    
    // MARK: QUIT POWERMETRIX
    
    @IBAction func clickQuit(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    // MARK: SHOW ABOUT WINDOW
    
    @IBAction func clickAbout(_ sender: Any) {
        self.aboutWindow.makeKeyAndOrderFront(nil)
        self.aboutWindow.level = NSWindow.Level.modalPanel
        self.aboutWindow.center()
    }
    
    
    
    
    
    
    
    
    
    /*
    /// DEBUG
    
    func test(metrix:[String:AnyObject]) {
        DispatchQueue.global().async {
            let hw_model = metrix["hw_model"] as? String ?? "Unknown Mac"
            let gpu = metrix["gpu"] as? [String:AnyObject]
            let gpu_freq_hz = gpu?["freq_hz"] as? NSNumber ?? 0
            let gpu_gpu_energy = gpu?["gpu_energy"] as? NSNumber ?? 0
            let processor = metrix["processor"] as? [String:AnyObject]
            let processor_package_energy = processor?["package_energy"] as? NSNumber ?? 0
            let cpu_cpu_energy = processor?["cpu_energy"] as? NSNumber ?? 0
            let cpu_dram_energy = processor?["dram_energy"] as? NSNumber ?? 0
            
            print(hw_model)
            print("Package energy: \(processor_package_energy) mW")
            print("GPU frequency: \(gpu_freq_hz) Mhz")
            print("GPU energy: \(gpu_gpu_energy) mW")
            print("DRAM energy: \(cpu_dram_energy) mW")
            print("CPU energy: \(cpu_cpu_energy) mW")
            
            
            
            let processor_clusters = processor?["clusters"] as? [[String:AnyObject]] ?? NSArray() as! [[String : AnyObject]]
            for cluster in processor_clusters {
                // clusters
                let cluster_name = cluster["name"] as? String ?? String()
                let cluster_cpus = cluster["cpus"] as? NSArray ?? NSArray()
                let cluster_freq_hz = ((cluster["freq_hz"] as? Int ?? 0)) / 1000000
                let cluster_power = (cluster["power"]) as? NSNumber ?? 0
                print("\(cluster_name) (\(cluster_cpus.count) CPUs) power: \(cluster_power) mW, HW active frequency: \(cluster_freq_hz) Mhz")
                // cpus
                for cpu in cluster_cpus {
                    if let cpudict = cpu as? [String:AnyObject] {
                        print("- \(cluster_name) CPU \(cpudict["cpu"] as? NSNumber ?? -1) frequency: \((cpudict["freq_hz"] as? Int ?? 0) / 1000000)")
                    }
                }
                
            }
            
            
            
        }
    }
    */
    
    
    
    
    
    
}
