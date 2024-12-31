//
//  DetailMap.swift
//  DateSpot
//
//  Created by 신정섭 on 12/26/24.
//
import SwiftUI
import MapKit


struct DetailMap: View {
    @StateObject private var viewModel = DetailMapViewModel()
//    @StateObject var predictVM = PredictViewModel()
    @Binding var restaurants : Restaurant
    @Binding var images : UIImage
    @Binding var rates : Int
    @State var selectedMarker : MKMapItem?
    @State var selectValue = false
    @State var selectedParkingId : String?
    @State var loadingStatus = false
    
    var body: some View {
        NavigationView {
            if loadingStatus == false{
                ProgressView("Loading...")
                    .font(.headline)
            }else{
                ZStack {
                    Map(position:$viewModel.cameraPosition, selection: $selectedMarker) {
                        UserAnnotation()
                        
                        ForEach(viewModel.nearParking, id: \.id) { parking in
                            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: parking.latitude, longitude: parking.longitude)))
                            Marker(parking.name, systemImage: "car.fill", coordinate: parking.coordinate)
                                .tint(.blue)
                                .tag(mapItem)
                            
                        }
                        Marker(restaurants.name, systemImage: "star.fill", coordinate: CLLocationCoordinate2D(latitude: restaurants.lat, longitude: restaurants.lng))
                        
                    }
                    .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        // 하단 카드 뷰
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(restaurants.name)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    
                                    HStack {
                                        
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        rates != 0 ? Text("\(String(rates)).0") : Text("별점을 입력하세요")
                                    }
                                }
                                
                                Spacer()
                                
                                Image(uiImage: images)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text(restaurants.address)
                                }
                                
                                HStack {
                                    Image(systemName: "clock.fill")
                                    Text(restaurants.operatingHour)
                                }
                                
                                
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text(restaurants.contactInfo)
                                }
                                
                            }
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(radius: 5)
                        .padding()
                    }
                }
                
                }
            }
                .onAppear {
                    viewModel.updateCameraPosition(latitude: restaurants.lat, longitude: restaurants.lng)
                    viewModel.fetchParkingInfo(lat: restaurants.lat, lng: restaurants.lng)
                    loadingStatus = true
//                    if viewModel.nearParking.contains(where: { parking in
//                        parking.name == "여의도공원앞(구)" }) {
                        Task {
                            await viewModel.predictYeouido()
                        }
//                    }
                    
                }

        } // View
    } // End

