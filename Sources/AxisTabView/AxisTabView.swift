//
//  AxisTabView.swift
//  AxisTabView
//
//  Created by jasu on 2022/03/12.
//  Copyright (c) 2022 jasu All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished
//  to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
//  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
//  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import SwiftUI

public struct AxisTabView<SelectionValue, Background, Content> : View where SelectionValue : Hashable, Background : View, Content : View {
    
    private let viewModel: ATViewModel<SelectionValue>
    @StateObject private var stateViewModel: ATStateViewModel<SelectionValue> = .init()
    
    /// Defines the settings for the tab view.
    private let constant: ATConstant
    
    /// The style of the background view.
    public var background: ((ATTabState) -> Background)
    public var content:  () -> Content
    
    public var body: some View {
        GeometryReader { proxy in
            if proxy.size != .zero {
                ZStack {
                    Color.clear
                    content()
                        .padding(edgeSet, constant.screen.activeSafeArea ? constant.tab.normalSize.height + getSafeArea(proxy) : 0)
                }
                .overlayPreferenceValue(ATTabItemPreferenceKey.self) { items in
                    let items = items.prefix(getLimitItemCount(size: proxy.size))
                    let state = ATTabState(constant: constant, itemCount: items.count, previousIndex: stateViewModel.previousIndex, currentIndex: stateViewModel.indexOfTag(viewModel.selection), size: proxy.size, safeAreaInsets: proxy.safeAreaInsets)
                    VStack(spacing: 0) {
                        if constant.axisMode == .bottom {
                            Spacer()
                        }
                        getTabContent(Array(items))
                            .frame(width: proxy.size.width, height: constant.tab.normalSize.height)
                            .padding(edgeSet, getSafeArea(proxy))
                            .animation(constant.tab.animation ?? .none, value: viewModel.selection)
                            .background(background(state))
                        if constant.axisMode == .top {
                            Spacer()
                        }
                    }
                }
                .edgesIgnoringSafeArea(edgeSet)
            }
        }
        .environmentObject(viewModel)
        .environmentObject(stateViewModel)
    }
    
    //MARK: - Properties
    private var edgeSet: Edge.Set {
        constant.axisMode == .bottom ? .bottom : .top
    }
    
    //MARK: - Methods
    private func getItemWidth(tag: SelectionValue) -> CGFloat {
        if tag == self.viewModel.selection {
            if constant.tab.selectWidth > 0 {
                return constant.tab.selectWidth
            }
        }
        return constant.tab.normalSize.width
    }
    
    private func getTabContent(_ items: [ATTabItem]) -> some View {
        HStack(alignment: constant.axisMode == .bottom ? .top : .bottom, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if constant.tab.spacingMode == .center {
                    ZStack {
                        if item.tag as! SelectionValue == viewModel.selection {
                            item.select
                                .transition(constant.tab.transition)
                        }else {
                            item.normal
                                .transition(constant.tab.transition)
                        }
                    }
                    .frame(width: getItemWidth(tag: item.tag as! SelectionValue),
                           height: constant.tab.normalSize.height)
                    .onTapGesture {
                        if let tag = item.tag as? SelectionValue {
                            self.viewModel.selection = tag
                        }
                    }
                    if index != items.count - 1 {
                        Spacer().frame(width: constant.tab.spacing)
                    }
                }else {
                    Spacer()
                    ZStack {
                        if item.tag as! SelectionValue == viewModel.selection {
                            item.select
                                .transition(constant.tab.transition)
                        }else {
                            item.normal
                                .transition(constant.tab.transition)
                        }
                    }
                    .frame(width: getItemWidth(tag: item.tag as! SelectionValue),
                           height: constant.tab.normalSize.height)
                    .onTapGesture {
                        if let tag = item.tag as? SelectionValue {
                            self.viewModel.selection = tag
                        }
                    }
                    if index == items.count - 1 {
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            stateViewModel.tags = items.map{ $0.tag as! SelectionValue }
        }
    }
    
    /// Returns the maximum number of tab buttons that can be displayed in the tab view.
    /// - Parameter size: The total size of the tab view.
    /// - Returns: -
    private func getLimitItemCount(size: CGSize) -> Int {
        let total = size.width - (constant.tab.selectWidth > 0 ? constant.tab.selectWidth : constant.tab.normalSize.width)
        return Int(total * 0.85 / constant.tab.normalSize.width) + 1
    }
    
    /// Returns the safe area value according to the axisMode.
    /// - Parameter proxy: Geometry proxy
    /// - Returns: -
    private func getSafeArea(_ proxy: GeometryProxy) -> CGFloat {
        constant.axisMode == .bottom ? proxy.safeAreaInsets.bottom : proxy.safeAreaInsets.top
    }
}

public extension AxisTabView where SelectionValue: Hashable, Background: View, Content: View {
    
    /// Initializes `AxisTabView`.
    /// - Parameters:
    ///   - selection: Creates an instance that selects from content associated with Selection values.
    ///   - constant: Defines the settings for the tab view.
    ///   - background: The style of the background view.
    ///   - content: Content views with tab items applied.
    init(selection: Binding<SelectionValue>, constant: ATConstant = .init(), @ViewBuilder background: @escaping (ATTabState) -> Background, @ViewBuilder content: @escaping () -> Content) {
        self.viewModel = ATViewModel(selection: selection, constant: constant)
        self.background = background
        self.constant = constant
        self.content = content
    }
}

struct AxisTabView_Previews: PreviewProvider {
    static var previews: some View {
        TabViewPreview()
    }
}

