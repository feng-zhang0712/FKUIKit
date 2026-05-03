//
// FKMultiPickerSampleAddressData.swift
//

import Foundation

/// Sample province → city → district → street hierarchy for demos and UI tests (not production geodata).
public enum FKMultiPickerSampleAddressData {
  public static let tree: [FKMultiPickerNode] = [
    FKMultiPickerNode(
      id: "110000",
      title: "Beijing",
      children: [
        FKMultiPickerNode(
          id: "110100",
          title: "Beijing City",
          children: [
            FKMultiPickerNode(
              id: "110105",
              title: "Chaoyang District",
              children: [
                FKMultiPickerNode(id: "110105001", title: "Jianguomen Street"),
                FKMultiPickerNode(id: "110105002", title: "Sanlitun Street"),
              ]
            ),
            FKMultiPickerNode(
              id: "110108",
              title: "Haidian District",
              children: [
                FKMultiPickerNode(id: "110108001", title: "Zhongguancun Street"),
                FKMultiPickerNode(id: "110108002", title: "Qinghe Street"),
              ]
            ),
          ]
        )
      ]
    ),
    FKMultiPickerNode(
      id: "310000",
      title: "Shanghai",
      children: [
        FKMultiPickerNode(
          id: "310100",
          title: "Shanghai City",
          children: [
            FKMultiPickerNode(
              id: "310115",
              title: "Pudong New Area",
              children: [
                FKMultiPickerNode(id: "310115001", title: "Lujiazui Street"),
                FKMultiPickerNode(id: "310115002", title: "Jinqiao Street"),
              ]
            ),
            FKMultiPickerNode(
              id: "310104",
              title: "Xuhui District",
              children: [
                FKMultiPickerNode(id: "310104001", title: "Tianping Road Street"),
                FKMultiPickerNode(id: "310104002", title: "Xujiahui Street"),
              ]
            ),
          ]
        )
      ]
    ),
    FKMultiPickerNode(
      id: "440000",
      title: "Guangdong",
      children: [
        FKMultiPickerNode(
          id: "440100",
          title: "Guangzhou",
          children: [
            FKMultiPickerNode(
              id: "440106",
              title: "Tianhe District",
              children: [
                FKMultiPickerNode(id: "440106001", title: "Shipai Street"),
                FKMultiPickerNode(id: "440106002", title: "Yuancun Street"),
              ]
            ),
            FKMultiPickerNode(
              id: "440103",
              title: "Liwan District",
              children: [
                FKMultiPickerNode(id: "440103001", title: "Xiguan Street"),
                FKMultiPickerNode(id: "440103002", title: "Dongsha Street"),
              ]
            ),
          ]
        ),
        FKMultiPickerNode(
          id: "440300",
          title: "Shenzhen",
          children: [
            FKMultiPickerNode(
              id: "440305",
              title: "Nanshan District",
              children: [
                FKMultiPickerNode(id: "440305001", title: "Yuehai Street"),
                FKMultiPickerNode(id: "440305002", title: "Taoyuan Street"),
              ]
            ),
            FKMultiPickerNode(
              id: "440304",
              title: "Futian District",
              children: [
                FKMultiPickerNode(id: "440304001", title: "Futian Street"),
                FKMultiPickerNode(id: "440304002", title: "Lianhua Street"),
              ]
            ),
          ]
        ),
      ]
    ),
    FKMultiPickerNode(
      id: "510000",
      title: "Sichuan",
      children: [
        FKMultiPickerNode(
          id: "510100",
          title: "Chengdu",
          children: [
            FKMultiPickerNode(
              id: "510107",
              title: "Wuhou District",
              children: [
                FKMultiPickerNode(id: "510107001", title: "Jinyang Street"),
                FKMultiPickerNode(id: "510107002", title: "Huaxing Street"),
              ]
            ),
            FKMultiPickerNode(
              id: "510104",
              title: "Jinjiang District",
              children: [
                FKMultiPickerNode(id: "510104001", title: "Yanshikou Street"),
                FKMultiPickerNode(id: "510104002", title: "Hejiangting Street"),
              ]
            ),
          ]
        )
      ]
    ),
  ]
}

/// `FKMultiPickerDataProviding` that exposes `FKMultiPickerSampleAddressData.tree` as roots.
@MainActor
public final class FKMultiPickerSampleAddressDataProvider: FKMultiPickerDataProviding {
  public init() {}

  public func rootNodes() -> [FKMultiPickerNode] {
    FKMultiPickerSampleAddressData.tree
  }
}
