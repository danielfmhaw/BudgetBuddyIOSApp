//
//  ContentView.swift
//  SwiftChartsDemo
//
//  Created by Daniel Mendes on 28.04.23.
//

import SwiftUI
import Charts

struct Item:Identifiable{
    var id = UUID()
    var type:String
    let value:Double
}

struct ChartView: View {
    let items:[Item]=[
        Item(type: "Engineering", value: 100),
        Item(type: "Design", value: 35),
        Item(type: "Operations", value: 72),
        Item(type: "Sales", value: 22),
        Item(type: "Mgmt", value: 130),
        Item(type: "Testing", value: 122),
        Item(type: "Deployment", value: 66),
        Item(type: "Analytics", value: 43),
        Item(type: "PW", value: 97),
        Item(type: "Top-Management", value: 88)
    ]
    
    
    var body: some View {
        NavigationView{
            ScrollView{
                //bar, line,area,ruler,point
                Chart(items){item in
                    BarMark(
                        x: .value("Department", item.type),
                        y: .value("Profit", item.value)
                    )
                    .foregroundStyle(Color.red.gradient)
                }
                .frame(height: 200)
                .padding()
                
                Chart(items){item in
                    LineMark(
                        x: .value("Department", item.type),
                        y: .value("Profit", item.value)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
                .frame(height: 200)
                .padding()
                
                Chart(items){item in
                    AreaMark(
                        x: .value("Department", item.type),
                        y: .value("Profit", item.value)
                    )
                    .foregroundStyle(Color.green.gradient)
                }
                .frame(height: 200)
                .padding()
                
                Chart(items){item in
                    PointMark(
                        x: .value("Department", item.type),
                        y: .value("Profit", item.value)
                    )
                    .foregroundStyle(Color.pink.gradient)
                }
                .frame(height: 200)
                .padding()
                
            }
            .navigationTitle("Charts")
        }
    }
}
