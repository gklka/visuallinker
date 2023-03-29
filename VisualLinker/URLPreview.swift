//
//  URLPreview.swift
//  VisualLinker
//
//  Created by GK on 2023.01.30..
//

import SwiftUI
import LinkPresentation

struct URLPreview : NSViewRepresentable {
    var previewURL:URL

    func makeNSView(context: Context) -> LPLinkView {
        LPLinkView(url: previewURL)
    }

    func updateNSView(_ view: LPLinkView, context: Context) {
        // New instance for each update

        let provider = LPMetadataProvider()

        provider.startFetchingMetadata(for: previewURL) { (metadata, error) in
            if let metadata = metadata {
                DispatchQueue.main.async {
                    view.metadata = metadata
//                    view.fittingSize
                }
            }
        }
    }
}
