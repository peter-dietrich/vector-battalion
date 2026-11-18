import SwiftUI
import SceneKit

final class BattalionGame: ObservableObject {
    @Published private(set) var squad = 1
    @Published private(set) var score = 0
    @Published private(set) var wave = 1
    @Published private(set) var isPaused = false
    @Published private(set) var isGameOver = false
    @Published private(set) var bestScore = UserDefaults.standard.integer(forKey: "VectorBattalion.bestScore")

    let scene = SCNScene()
    let camera = SCNNode()
    private let squadRoot = SCNNode()
    private var soldiers: [SCNNode] = []
    private var targets: [Target] = []
    private var bullets: [Bullet] = []
    private var desiredX: Float = 0
    private var currentX: Float = 0
    private var lastTime: TimeInterval?
    private var spawnClock: Float = 0
    private var fireClock: Float = 0
    private var elapsed: Float = 0
    private let lanes: [Float] = [-3.7, 0, 3.7]

    enum TargetKind { case recruit, enemy, upgrade }
    struct Target {
        let node: SCNNode
        let label: SCNNode
        let lane: Int
        let kind: TargetKind
        var hp: Int
        let reward: Int
    }
    struct Bullet {
        let node: SCNNode
        let x: Float
        var z: Float
        let damage: Int
    }

    init() { buildScene(); reset() }

    func steer(normalized: Float) {
        desiredX = max(-4.65, min(4.65, (normalized - 0.5) * 10))
    }

    func togglePause() {
        guard !isGameOver else { return }
        isPaused.toggle()
        lastTime = nil
    }

    func reset() {
        targets.forEach { $0.node.removeFromParentNode() }
        bullets.forEach { $0.node.removeFromParentNode() }
        soldiers.forEach { $0.removeFromParentNode() }
        targets.removeAll()
        bullets.removeAll()
        soldiers.removeAll()
        squad = 1
        score = 0
        wave = 1
        isPaused = false
        isGameOver = false
        desiredX = 0
        currentX = 0
        elapsed = 0
        spawnClock = 0
        fireClock = 0
        lastTime = nil
        squadRoot.position.x = 0
        updateFormation()
        spawnRow()
    }

    private func material(_ color: NSColor) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = color
        m.metalness.contents = 0.22
        m.roughness.contents = 0.45
        return m
    }

    private func block(_ w: CGFloat, _ h: CGFloat, _ l: CGFloat, _ color: NSColor) -> SCNNode {
        let geometry = SCNBox(width: w, height: h, length: l, chamferRadius: 0.06)
        geometry.materials = [material(color)]
        return SCNNode(geometry: geometry)
    }

    private func buildScene() {
        scene.background.contents = NSColor(red: 0.025, green: 0.06, blue: 0.11, alpha: 1)
        scene.fogColor = NSColor(red: 0.035, green: 0.10, blue: 0.17, alpha: 1)
        scene.fogStartDistance = 75
        scene.fogEndDistance = 125

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 550
        scene.rootNode.addChildNode(ambient)

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 1200
        sun.light?.castsShadow = true
        sun.eulerAngles = SCNVector3(-0.9, -0.6, 0)
        scene.rootNode.addChildNode(sun)

        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 58
        camera.camera?.zNear = 0.1
        camera.camera?.zFar = 180
        camera.position = SCNVector3(0, 16, 23)
        camera.look(at: SCNVector3(0, 0, -16))
        scene.rootNode.addChildNode(camera)

        let ground = block(240, 0.2, 240, NSColor(red: 0.055, green: 0.115, blue: 0.13, alpha: 1))
        ground.position = SCNVector3(0, -0.35, -40)
        scene.rootNode.addChildNode(ground)

        let road = block(11, 0.12, 150, NSColor(red: 0.095, green: 0.13, blue: 0.19, alpha: 1))
        road.position = SCNVector3(0, -0.16, -53)
        scene.rootNode.addChildNode(road)

        for x in ([-5.55, 5.55] as [Float]) {
            let edge = block(0.14, 0.2, 150, .cyan)
            edge.position = SCNVector3(x, 0.06, -53)
            scene.rootNode.addChildNode(edge)
        }
        for z in stride(from: -120, through: 12, by: 5) {
            for x in ([-1.85, 1.85] as [Float]) {
                let stripe = block(0.07, 0.016, 2, .white)
                stripe.position = SCNVector3(x, -0.07, Float(z))
                scene.rootNode.addChildNode(stripe)
            }
        }
        for z in stride(from: -115, through: 14, by: 12) {
            for side in ([-1, 1] as [Float]) {
                let height = Float.random(in: 2...9)
                let building = block(CGFloat(Float.random(in: 1.2...3.5)), CGFloat(height), CGFloat(Float.random(in: 2...4)), NSColor(red: 0.055, green: 0.18, blue: 0.23, alpha: 1))
                building.position = SCNVector3(side * Float.random(in: 9...18), height / 2, Float(z))
                scene.rootNode.addChildNode(building)
            }
        }
        scene.rootNode.addChildNode(squadRoot)
    }

    private func soldier() -> SCNNode {
        let root = SCNNode()
        let body = block(0.46, 0.8, 0.35, NSColor(red: 0.05, green: 0.78, blue: 0.70, alpha: 1))
        body.position.y = 0.84
        root.addChildNode(body)
        let head = SCNNode(geometry: SCNSphere(radius: 0.24))
        head.geometry?.firstMaterial?.diffuse.contents = NSColor(red: 0.82, green: 0.92, blue: 0.94, alpha: 1)
        head.position.y = 1.48
        root.addChildNode(head)
        let rifle = block(0.12, 0.13, 0.95, .darkGray)
        rifle.position = SCNVector3(0.23, 0.99, -0.55)
        root.addChildNode(rifle)
        return root
    }

    private func updateFormation() {
        let count = min(squad, 36)
        while soldiers.count < count {
            let member = soldier()
            squadRoot.addChildNode(member)
            soldiers.append(member)
        }
        while soldiers.count > count {
            soldiers.removeLast().removeFromParentNode()
        }
        // Compact formation fits inside the visible road and its actual size matches the HUD.
        // Each row holds at most six soldiers; older recruits fill the front ranks first.
        let columns = min(6, max(1, count))
        for (i, member) in soldiers.enumerated() {
            let row = i / columns
            let column = i % columns
            let itemsInRow = min(columns, count - row * columns)
            let lateral = (Float(column) - Float(itemsInRow - 1) * 0.5) * 0.72
            member.position = SCNVector3(lateral, 0, 1.15 + Float(row) * 0.64)
        }
    }

    private func spawnRow() {
        let special = Int.random(in: 0..<3)
        for lane in 0..<3 {
            let kind: TargetKind
            if lane == special {
                kind = .upgrade
            } else {
                kind = Bool.random() ? .recruit : .enemy
            }
            let hp: Int
            switch kind {
            case .upgrade: hp = 15 + 4 * wave
            case .recruit: hp = 8 + 3 * wave
            case .enemy: hp = 8 + 3 * wave
            }
            let reward: Int
            switch kind {
            case .upgrade: reward = 2
            case .recruit: reward = 1
            case .enemy: reward = 0
            }
            let color: NSColor
            switch kind {
            case .enemy: color = .systemRed
            case .upgrade: color = .systemYellow
            case .recruit: color = .systemCyan
            }
            let node = SCNNode()
            let body = block(2.45, 2.25, 1.7, color)
            body.position.y = 1.2
            node.addChildNode(body)

            let text = SCNText(string: kind == .enemy ? String(hp) : "\(hp)  +\(reward)", extrusionDepth: 0.05)
            text.font = NSFont.monospacedDigitSystemFont(ofSize: 0.65, weight: .black)
            text.firstMaterial?.diffuse.contents = NSColor.black
            text.flatness = 0.08
            let label = SCNNode(geometry: text)
            let bounds = text.boundingBox
            let labelOffset = -Float(bounds.max.x - bounds.min.x) / 2
            label.position = SCNVector3(labelOffset, 1.18, 0.93)
            node.addChildNode(label)
            node.position = SCNVector3(lanes[lane], 0, -68)
            scene.rootNode.addChildNode(node)
            targets.append(Target(node: node, label: label, lane: lane, kind: kind, hp: hp, reward: reward))
        }
    }

    func tick(_ time: TimeInterval) {
        guard !isPaused && !isGameOver else { lastTime = time; return }
        guard let previous = lastTime else { lastTime = time; return }
        let dt = min(0.05, max(0, Float(time - previous)))
        lastTime = time
        elapsed += dt
        currentX += (desiredX - currentX) * min(1, dt * 13)
        squadRoot.position.x = CGFloat(currentX)

        spawnClock += dt
        fireClock += dt
        if spawnClock > max(2.8, 5.4 - Float(wave) * 0.13) {
            spawnClock = 0
            spawnRow()
        }

        let cadence = max(0.065, 0.22 - Float(squad) * 0.004)
        if fireClock >= cadence {
            fireClock = 0
            let shots = min(3, max(1, squad / 5 + 1))
            for i in 0..<shots {
                let x = currentX + (Float(i) - Float(shots - 1) / 2) * 0.43
                let orb = SCNNode(geometry: SCNSphere(radius: 0.115))
                orb.geometry?.firstMaterial?.diffuse.contents = NSColor.cyan
                orb.geometry?.firstMaterial?.lightingModel = .constant
                orb.position = SCNVector3(x, 1.2, 3.7)
                scene.rootNode.addChildNode(orb)
                bullets.append(Bullet(node: orb, x: x, z: 3.7, damage: max(1, squad / 7)))
            }
        }

        for i in bullets.indices {
            bullets[i].z -= 52 * dt
            bullets[i].node.position.z = CGFloat(bullets[i].z)
        }
        for i in targets.indices {
            targets[i].node.position.z += CGFloat((8 + Float(wave) * 0.65) * dt)
        }

        var hitBullets = Set<Int>()
        var destroyed = Set<Int>()
        for bulletIndex in bullets.indices {
            let shot = bullets[bulletIndex]
            if shot.z < -74 {
                hitBullets.insert(bulletIndex)
                continue
            }
            for targetIndex in targets.indices where !destroyed.contains(targetIndex) {
                let target = targets[targetIndex]
                let targetZ = Float(target.node.position.z)
                let withinDepth = abs(shot.z - targetZ) < 1
                let withinLane = abs(shot.x - lanes[target.lane]) < 1.35
                if withinDepth && withinLane {
                    hitBullets.insert(bulletIndex)
                    targets[targetIndex].hp -= shot.damage
                    if targets[targetIndex].hp <= 0 {
                        destroyed.insert(targetIndex)
                    } else {
                        (targets[targetIndex].label.geometry as? SCNText)?.string = target.kind == .enemy
                            ? String(targets[targetIndex].hp)
                            : "\(targets[targetIndex].hp)  +\(target.reward)"
                    }
                    break
                }
            }
        }
        for index in hitBullets.sorted(by: >) {
            bullets[index].node.removeFromParentNode()
            bullets.remove(at: index)
        }
        for index in destroyed.sorted(by: >) {
            let target = targets.remove(at: index)
            target.node.removeFromParentNode()
            if target.kind == .enemy {
                score += 75
            } else {
                let gained = min(target.reward, 36 - squad)
                squad += max(0, gained)
                updateFormation()
                score += 100 * target.reward
            }
        }

        var passed: [Int] = []
        for index in targets.indices where targets[index].node.position.z > 5.5 {
            let target = targets[index]
            if abs(Float(target.node.position.x) - currentX) < 2.3 && target.kind == .enemy {
                squad = max(0, squad - max(1, wave / 2))
                updateFormation()
            }
            passed.append(index)
        }
        for index in passed.reversed() {
            targets[index].node.removeFromParentNode()
            targets.remove(at: index)
        }

        if squad == 0 { isGameOver = true }
        let nextWave = 1 + Int(elapsed / 30)
        if nextWave != wave {
            wave = nextWave
            score += 100 * wave
        }
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(score, forKey: "VectorBattalion.bestScore")
        }
    }
}

struct BattalionSceneView: NSViewRepresentable {
    @ObservedObject var game: BattalionGame

    func makeCoordinator() -> Coordinator { Coordinator(game: game) }

    func makeNSView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = game.scene
        view.pointOfView = game.camera
        view.backgroundColor = .black
        view.antialiasingMode = .multisampling4X
        view.rendersContinuously = true
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ view: SCNView, context: Context) {
        context.coordinator.game = game
    }

    final class Coordinator: NSObject, SCNSceneRendererDelegate {
        var game: BattalionGame
        init(game: BattalionGame) { self.game = game }
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            DispatchQueue.main.async { [weak self] in
                self?.game.tick(time)
            }
        }
    }
}
