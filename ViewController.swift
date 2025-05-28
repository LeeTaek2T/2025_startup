

import UIKit
import SceneKit
import SceneKit.ModelIO
import ModelIO
import UniformTypeIdentifiers


class SimulationViewController: UIViewController , UIDocumentPickerDelegate,FurnitureSelectionDelegate{

    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var importAndConvertButton: UIButton!
    @IBOutlet weak var stored3dFurnitureButton: UIButton!
    @IBOutlet weak var sceneView: SCNView!
    var selectedNode: SCNNode?
    var sceneLightNode: SCNNode?
    var previousTouchLocation: CGPoint?
    var originalMaterials: [SCNNode: [SCNMaterial]] = [:]

    var hasAppearedOnce = false  // 처음엔 false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        let upImage = UIImage(systemName: "arrow.up.circle.fill", withConfiguration: config)
        let downImage = UIImage(systemName: "arrow.down.circle.fill", withConfiguration: config)
        downButton.setImage(downImage, for: .normal)
        downButton.tintColor = .systemBlue
        upButton.setImage(upImage,for:.normal)
        downButton.tintColor = .systemBlue
        downButton.isHidden=true
        upButton.isHidden=true
        brightnessSlider.isHidden=true
        stored3dFurnitureButton.isHidden=true
        
        sceneView.autoenablesDefaultLighting = false

    }
    
    @IBAction func pickUSDZfile(_ sender: Any) {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType(filenameExtension: "usdz")!])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
        importAndConvertButton.isHidden = true
        downButton.isHidden=false
        upButton.isHidden=false
        brightnessSlider.isHidden=false
        stored3dFurnitureButton.isHidden=false
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        convertUSDZToSCNAndLoad(url: url)
    }
    
    func convertUSDZToSCNAndLoad(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ 접근 권한 실패")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let asset = MDLAsset(url: url)
        asset.loadTextures()
        let scene = SCNScene(mdlAsset: asset)

        // ✅ 저장 위치
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let scnURL = documents.appendingPathComponent("converted.scn")
        
        do {
            try scene.write(to: scnURL, options: nil, delegate: nil, progressHandler: nil)
            print("✅ .scn 파일로 저장 완료: \(scnURL)")
            
            let loadedScene = try SCNScene(url: scnURL, options: nil)

//            // 🌑 모델 머티리얼 어둡게 처리
            darkenUSDZMaterials(in: loadedScene.rootNode)

            // ✅ 조명 설정 등 추가 구성
            setupSceneExtras(scene: loadedScene)

            // ✅ 씬 적용
            sceneView.scene = loadedScene
        } catch {
            print("❌ 저장/불러오기 실패: \(error)")
        }
    }
    func darkenUSDZMaterials(in node: SCNNode) {
        for child in node.childNodes {
            darkenUSDZMaterials(in: child)  // 재귀 호출
            if let geometry = child.geometry {
                for material in geometry.materials {
                    material.multiply.contents = UIColor(white: 0.5, alpha: 1.0)  // 🌑 밤 느낌
                }
            }
        }
    }

    func setupSceneExtras(scene: SCNScene) {
//        // ✅ 구체 머티리얼 (빛나는 효과)
//        let sphere = SCNSphere(radius: 0.3)
//        let glowingMaterial = SCNMaterial()
//        glowingMaterial.diffuse.contents = UIColor.white
//        glowingMaterial.emission.contents = UIColor.yellow
//        glowingMaterial.lightingModel = .constant
//        glowingMaterial.transparency = 0.9
//        glowingMaterial.blendMode = .add
//        sphere.materials = [glowingMaterial]
//        
//        let sphereNode = SCNNode(geometry: sphere)
//        sphereNode.position = SCNVector3(0, 0, 0)
//        sphereNode.name = "furniture_lighting"
//        scene.rootNode.addChildNode(sphereNode)
////         ✅ 구체에 부착할 조명
//        let sphereLight = SCNLight()
//        sphereLight.type = .omni
//        sphereLight.intensity = 400
//        sphereLight.color = UIColor.yellow
//        sphereLight.temperature = 3000
//        sphereLight.attenuationStartDistance = 0.5
//        sphereLight.attenuationEndDistance = 4.0
//        sphereLight.attenuationFalloffExponent = 2.0
//        sphereLight.castsShadow = true
//        sphereLight.shadowSampleCount = 4
//        sphereLight.shadowRadius = 3
//
//        let sphereLightNode = SCNNode()
//        sphereLightNode.light = sphereLight
//        sphereLightNode.position = SCNVector3(0, 0, 0)
//        sphereNode.addChildNode(sphereLightNode)

        let adjustableLight = SCNLight()
        adjustableLight.type = .omni
        adjustableLight.intensity = 0  // 🌞 낮처럼 밝게
        adjustableLight.color = UIColor.white

        let adjustableLightNode = SCNNode()
        adjustableLightNode.light = adjustableLight
        adjustableLightNode.position = SCNVector3(0, 5, 5)

        scene.rootNode.addChildNode(adjustableLightNode)
        self.sceneLightNode = adjustableLightNode  // 슬라이더로 조작할 대상
    }
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: sceneView)
        let hits = sceneView.hitTest(location, options: nil)

        if let hit = hits.first,
           let newSelected = findFurnitureContainer(node: hit.node) {

            // ✅ 기존 선택 해제
            if let previous = selectedNode {
                restoreOriginalMaterials(node: previous)
            }

            // ✅ 새로 선택
            selectedNode = newSelected
            sceneView.allowsCameraControl = false
            highlight(node: newSelected)

            print("✅ \(newSelected.name ?? "") 선택됨")
        } else {
            // ✅ 아무것도 선택되지 않았을 때
            if let previous = selectedNode {
                restoreOriginalMaterials(node: previous)
            }
            selectedNode = nil
            sceneView.allowsCameraControl = true
        }
    }
    func highlight(node: SCNNode) {
        node.enumerateChildNodes { child, _ in
            if let geometry = child.geometry {
                originalMaterials[child] = geometry.materials

                let highlightMaterial = SCNMaterial()
                highlightMaterial.diffuse.contents = UIColor.yellow.withAlphaComponent(0.5)
                highlightMaterial.emission.contents = UIColor.yellow
                highlightMaterial.lightingModel = .constant
                geometry.materials = [highlightMaterial]
            }
        }
    }
    func restoreOriginalMaterials(node: SCNNode) {
        node.enumerateChildNodes { child, _ in
            if let original = originalMaterials[child] {
                child.geometry?.materials = original
            }
        }
        originalMaterials.removeAll()
    }



    func findParentWithGeometry(node: SCNNode?) -> SCNNode? {
        var current = node
        while let c = current {
            if c.geometry != nil { return c }
            current = c.parent
        }
        return nil
    }


    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let node = selectedNode else { return }

        let location = touch.location(in: sceneView)

        // ✅ 현재 위치를 3D 공간의 위치로 투영
        let projectedOrigin = sceneView.projectPoint(node.position)
        let projectedNew = SCNVector3(Float(location.x), Float(location.y), projectedOrigin.z)

        // ✅ 다시 3D 공간으로 역투영
        let newWorldPosition = sceneView.unprojectPoint(projectedNew)

        // ✅ 새로운 위치로 이동
        node.position = newWorldPosition
    }


    @IBAction func moveCameraForward(_ sender: Any) {
        sceneView.defaultCameraController.translateInCameraSpaceBy(x: 0, y: 0, z: -1)
    }
    
    @IBAction func moveCameraBackward(_ sender: Any) {
        sceneView.defaultCameraController.translateInCameraSpaceBy(x: 0, y: 0, z: 1)
        }
    func adjustCamera(zDelta: Float) {
        guard let cameraNode = sceneView.scene?.rootNode.childNodes.first(where: { $0.camera != nil }) else {
            print("❌ 카메라 노드 없음")
            return
        }

        cameraNode.position.z += zDelta
        print("📷 카메라 위치: \(cameraNode.position)")
    }
    
    
    @IBAction func brightnessSliderChanged(_ sender: UISlider) {
        let ratio = CGFloat(sender.value)  // 0.0 ~ 1.0 (1.0: 낮, 0.0: 밤)
        
        // ✅ 낮에서 밤으로 점점 어두워지도록
        let nightIntensity = CGFloat(500)   // 완전한 밤 느낌
        let dayIntensity = CGFloat(5000)  // 아주 밝은 낮

        let newIntensity = nightIntensity + (dayIntensity - nightIntensity) * ratio
        sceneLightNode?.light?.intensity = newIntensity
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFurnitureList",
           let destination = segue.destination as? Selected3dFurnitureViewController {
            print("prepare sege 연결")
            destination.furnitureDelegate = self  // 🔗 연결!
        }
    }

    func constrainLightPosition(to node: SCNNode, offsetY: Float = 1.0) -> SCNTransformConstraint {
        return SCNTransformConstraint(inWorldSpace: true) { lightNode, _ in
            var t = lightNode.transform
            let pos = node.presentation.worldPosition
            t.m41 = pos.x
            t.m42 = pos.y - offsetY
            t.m43 = pos.z
            return t
        }
    }

    

    func didSelectUSDZModel(named fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "usdz") else {
            print("❌ 파일 못 찾음: \(fileName)")
            return
        }

        let asset = MDLAsset(url: url)
        asset.loadTextures()
        let tempScene = SCNScene(mdlAsset: asset)

        // ✅ 전체 모델을 감싸는 컨테이너 노드 생성
        let containerNode = SCNNode()
        containerNode.name = "furniture_\(fileName)"

        // ✅ 전체 모델 복제 후 컨테이너에 추가
        let modelNode = tempScene.rootNode.clone()
        for child in modelNode.childNodes {
            containerNode.addChildNode(child)
        }

        
        if fileName == "Ceiling_Light" {
            let light = SCNLight()
            light.type = .omni
            light.intensity = 80
            light.color = UIColor.yellow
            light.temperature=5000
            light.attenuationStartDistance = 0.5
            light.attenuationEndDistance = 4.0
            light.attenuationFalloffExponent = 2.0
            light.castsShadow = true
            light.shadowSampleCount = 4
            light.shadowRadius = 3

            let lightNode = SCNNode()
            lightNode.light = light

            // ✅ rootNode에 추가 → 빛은 전체 공간 기준으로 퍼짐
            sceneView.scene?.rootNode.addChildNode(lightNode)
            lightNode.constraints = [constrainLightPosition(to: containerNode, offsetY: 1.0)]

//            // ✅ 위치는 containerNode(조명 모델)와 함께 이동하도록 constraint 설정
//            let constraint = SCNTransformConstraint(inWorldSpace: true) { _, _ in
//                var transform = containerNode.worldTransform
//                transform.m42 -= 0.5  // 조명 모델 아래쪽에 위치
//                return transform
//            }
//            lightNode.constraints = [constraint]
//
//            // ✅ 조명을 반영할 수 있도록 재질 수정
//            containerNode.enumerateChildNodes { child, _ in
//                child.geometry?.materials.forEach {
//                    $0.lightingModel = .physicallyBased
//                }
//            }
        }





        // ✅ 크기 조절
        let (minVec, maxVec) = containerNode.boundingBox
        let size = SCNVector3(maxVec.x - minVec.x, maxVec.y - minVec.y, maxVec.z - minVec.z)
        let maxSize: Float = 1.0
        let maxDimension = max(size.x, size.y, size.z)
        if maxDimension > 0 {
            let scale = (maxSize / maxDimension) * 0.75
            containerNode.scale = SCNVector3(x: scale, y: scale, z: scale)
        }

        containerNode.position = SCNVector3(0, 0, 0)

        // ✅ 씬 없으면 새로 생성
        if sceneView.scene == nil {
            sceneView.scene = SCNScene()
        }

        // ✅ 기존 모델 제거
        if let old = sceneView.scene?.rootNode.childNode(withName: containerNode.name!, recursively: true) {
            old.removeFromParentNode()
        }

        sceneView.scene?.rootNode.addChildNode(containerNode)
        print("✅ 모델 추가 완료")
    }

    
    func findFurnitureContainer(node: SCNNode) -> SCNNode? {
        var current = node
        while current.parent != nil {
            if let name = current.name, name.starts(with: "furniture_") {
                return current
            }
            current = current.parent!
        }
        return nil
    }

}

