//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class RenderGlobalsPanel { /*: JTabbedPane {
 var generalPanel: JPanel
 var maxSamplingComboxBox: JComboBox
 var samplingPanel: JPanel
 var minSamplingComboBox: JComboBox
 var jLabel6: JLabel
 var jLabel5: JLabel
 var defaultRendererRadioButton: JRadioButton
 var bucketRendererRadioButton: JRadioButton
 var bucketRendererPanel: JPanel
 var jLabel2: JLabel
 var rendererPanel: JPanel
 var threadTextField: JTextField
 var threadCheckBox: JCheckBox
 var jLabel3: JLabel
 var threadsPanel: JPanel
 var jLabel1: JLabel
 var resolutionPanel: JPanel
 var resolutionYTextField: JTextField
 var resolutionXTextField: JTextField
 var resolutionCheckBox: JCheckBox

 // This method initializes this
 func initialize() {
 }

 // Auto-generated main method to display this JPanel inside a new JFrame.
 static func main(_ args: [String]) {
 	var frame: JFrame = JFrame()
 	frame.getContentPane().add(RenderGlobalsPanel())
 	frame.setDefaultCloseOperation(WindowConstants.DISPOSE_ON_CLOSE)
 	frame.pack()
 	frame.setVisible(true)
 }

 init() {
 	super()
 	initialize()
 	initGUI()
 }

 func initGUI() {
 	__try {
 		setPreferredSize(Dimension(400, 300))
 		{
 			generalPanel = JPanel()
 			var generalPanelLayout: FlowLayout = FlowLayout()
 			generalPanelLayout.setAlignment(FlowLayout.LEFT)
 			generalPanel.setLayout(generalPanelLayout)
 			self.addTab("General", nil, generalPanel, nil)
 			{
 				resolutionPanel = JPanel()
 				generalPanel.add(resolutionPanel)
 				var resolutionPanelLayout: FlowLayout = FlowLayout()
 				resolutionPanel.setLayout(resolutionPanelLayout)
 				resolutionPanel.setBorder(BorderFactory.createTitledBorder(BorderFactory.createEtchedBorder(BevelBorder.LOWERED), "Resolution", TitledBorder.LEADING, TitledBorder.TOP))
 				{
 					resolutionCheckBox = JCheckBox()
 					resolutionPanel.add(resolutionCheckBox)
 					resolutionCheckBox.setText("Override")
 				}
 				{
 					jLabel1 = JLabel()
 					resolutionPanel.add(jLabel1)
 					jLabel1.setText("Image Width:")
 				}
 				{
 					resolutionXTextField = JTextField()
 					resolutionPanel.add(resolutionXTextField)
 					resolutionXTextField.setText("640")
 					resolutionXTextField.setPreferredSize(java.awt.Dimension(50, 20))
 				}
 				{
 					jLabel2 = JLabel()
 					resolutionPanel.add(jLabel2)
 					jLabel2.setText("Image Height:")
 				}
 				{
 					resolutionYTextField = JTextField()
 					resolutionPanel.add(resolutionYTextField)
 					resolutionYTextField.setText("480")
 					resolutionYTextField.setPreferredSize(java.awt.Dimension(50, 20))
 				}
 			}
 			{
 				threadsPanel = JPanel()
 				generalPanel.add(threadsPanel)
 				threadsPanel.setBorder(BorderFactory.createTitledBorder(BorderFactory.createEtchedBorder(BevelBorder.LOWERED), "Threads", TitledBorder.LEADING, TitledBorder.TOP))
 				{
 					threadCheckBox = JCheckBox()
 					threadsPanel.add(threadCheckBox)
 					threadCheckBox.setText("Use All Processors")
 				}
 				{
 					jLabel3 = JLabel()
 					threadsPanel.add(jLabel3)
 					jLabel3.setText("Threads:")
 				}
 				{
 					threadTextField = JTextField()
 					threadsPanel.add(threadTextField)
 					threadTextField.setText("1")
 					threadTextField.setPreferredSize(java.awt.Dimension(50, 20))
 				}
 			}
 		}
 		{
 			rendererPanel = JPanel()
 			var rendererPanelLayout: FlowLayout = FlowLayout()
 			rendererPanelLayout.setAlignment(FlowLayout.LEFT)
 			rendererPanel.setLayout(rendererPanelLayout)
 			self.addTab("Renderer", nil, rendererPanel, nil)
 			{
 				defaultRendererRadioButton = JRadioButton()
 				rendererPanel.add(defaultRendererRadioButton)
 				defaultRendererRadioButton.setText("Default Renderer")
 			}
 			{
 				bucketRendererPanel = JPanel()
 				var bucketRendererPanelLayout: BoxLayout = BoxLayout(bucketRendererPanel, javax.swing.BoxLayout.Y_AXIS)
 				bucketRendererPanel.setLayout(bucketRendererPanelLayout)
 				rendererPanel.add(bucketRendererPanel)
 				bucketRendererPanel.setBorder(BorderFactory.createTitledBorder(BorderFactory.createEtchedBorder(BevelBorder.LOWERED), "Bucket Renderer", TitledBorder.LEADING, TitledBorder.TOP))
 				{
 					bucketRendererRadioButton = JRadioButton()
 					bucketRendererPanel.add(bucketRendererRadioButton)
 					bucketRendererRadioButton.setText("Enable")
 				}
 				{
 					samplingPanel = JPanel()
 					var samplingPanelLayout: GridLayout = GridLayout(2, 2)
 					samplingPanelLayout.setColumns(2)
 					samplingPanelLayout.setHgap(5)
 					samplingPanelLayout.setVgap(5)
 					samplingPanelLayout.setRows(2)
 					samplingPanel.setLayout(samplingPanelLayout)
 					bucketRendererPanel.add(samplingPanel)
 					{
 						jLabel5 = JLabel()
 						samplingPanel.add(jLabel5)
 						jLabel5.setText("Min:")
 					}
 					{
 var minSamplingComboBoxModel: ComboBoxModel = DefaultComboBoxModel((["Item One", "Item Two"] as [String]))
 						minSamplingComboBox = JComboBox()
 						samplingPanel.add(minSamplingComboBox)
 						minSamplingComboBox.setModel(minSamplingComboBoxModel)
 					}
 					{
 						jLabel6 = JLabel()
 						samplingPanel.add(jLabel6)
 						jLabel6.setText("Max:")
 					}
 					{
 var maxSamplingComboxBoxModel: ComboBoxModel = DefaultComboBoxModel((["Item One", "Item Two"] as [String]))
 						maxSamplingComboxBox = JComboBox()
 						samplingPanel.add(maxSamplingComboxBox)
 						maxSamplingComboxBox.setModel(maxSamplingComboxBoxModel)
 					}
 				}
 			}
 		}
 	}
 __catch; e: Exception do {
 		e.printStackTrace()
 	}
 } */
}
