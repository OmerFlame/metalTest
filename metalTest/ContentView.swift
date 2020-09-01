//
//  ContentView.swift
//  metalTest
//
//  Created by Omer Shamai on 9/1/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            MetalView()
        }
        .frame(width: 600, height: 600)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
