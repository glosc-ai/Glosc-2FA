//
//  QRCodeScannerView.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import AVFoundation
import SwiftUI

struct QRCodeScannerView: View {
    @Environment(\.dismiss) private var dismiss

    let onScanned: (String) -> Void

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    CameraScannerRepresentable { value in
                        onScanned(value)
                    } onError: { error in
                        errorMessage = error.localizedDescription
                    }
                    .ignoresSafeArea(edges: .bottom)
                } else {
                    ContentUnavailableView {
                        Label("当前设备无可用摄像头", systemImage: "camera.slash")
                    } description: {
                        Text("请在真机上使用二维码扫描，或返回上一页改用链接导入。")
                    }
                }
            }
            .navigationTitle("扫描二维码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .alert("扫描失败", isPresented: Binding(
                get: { errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        errorMessage = nil
                    }
                }
            )) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
}

private struct CameraScannerRepresentable: UIViewControllerRepresentable {
    let onScanned: (String) -> Void
    let onError: (Error) -> Void

    func makeUIViewController(context: Context) -> CameraScannerViewController {
        let controller = CameraScannerViewController()
        controller.onScanned = onScanned
        controller.onError = onError
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraScannerViewController, context: Context) {}
}

private final class CameraScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScanned: ((String) -> Void)?
    var onError: ((Error) -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        requestPermissionAndConfigureIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func requestPermissionAndConfigureIfNeeded() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSessionIfNeeded()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.configureSessionIfNeeded()
                    } else {
                        self.onError?(QRCodeScannerError.cameraAccessDenied)
                    }
                }
            }
        default:
            onError?(QRCodeScannerError.cameraAccessDenied)
        }
    }

    private func configureSessionIfNeeded() {
        guard previewLayer == nil else {
            if !session.isRunning {
                session.startRunning()
            }
            return
        }

        do {
            guard let device = AVCaptureDevice.default(for: .video) else {
                throw QRCodeScannerError.cameraUnavailable
            }

            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                throw QRCodeScannerError.configurationFailed
            }
            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else {
                throw QRCodeScannerError.configurationFailed
            }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer

            session.startRunning()
        } catch {
            onError?(error)
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasScanned,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else {
            return
        }

        hasScanned = true
        session.stopRunning()
        onScanned?(value)
    }
}

private enum QRCodeScannerError: LocalizedError {
    case cameraUnavailable
    case cameraAccessDenied
    case configurationFailed

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "当前设备没有可用摄像头。"
        case .cameraAccessDenied:
            return "没有摄像头权限，无法扫描二维码。"
        case .configurationFailed:
            return "二维码扫描器初始化失败。"
        }
    }
}