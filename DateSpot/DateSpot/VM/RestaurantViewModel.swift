//
//  RestaurantViewModel.swift
//  DateSpot
//
//  Created by 이원영 on 12/27/24.
//  Last Fixed: 12/28
//  Restaurant모델을 관리하는 ViewModel
//
//

import Foundation
import UIKit

@MainActor
class RestaurantViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = [] // 전체 레스토랑 리스트
    @Published var selectedRestaurant: Restaurant? // 선택된 레스토랑 상세 정보
    @Published var restaurantImages: [String: [UIImage]] = [:] // 레스토랑별 이미지 리스트
    private let baseURL = "https://fastapi.fre.today/restaurant/" // 기본 API URL
    private let imageBaseURL = "https://fastapi.fre.today/stream-images/" // 여러 이미지 API URL

    // Fetch Restaurants
    func fetchRestaurants() async {
        Task {
            do {
                let fetchedRestaurants = try await fetchRestaurantsFromAPI()
                self.restaurants = fetchedRestaurants
            } catch {
                print("Failed to fetch restaurants: \(error.localizedDescription)")
            }
        }
    }
    
    // Fetch Restaurant Detail
    func fetchRestaurantDetail(name: String = "3대삼계장인") async {
        print("Fetching restaurant detail")
        Task {
            do {
                let fetchedDetail = try await fetchRestaurantDetailFromAPI(name: name)
                self.selectedRestaurant = fetchedDetail

                // Fetch images for the selected restaurant
                if let images = await fetchImages(restaurantName: name) {
                    self.restaurantImages[name] = images
                }
            } catch {
                print("Failed to fetch restaurant detail: \(error.localizedDescription)")
            }
        }
    }
}

extension RestaurantViewModel {
    // Fetch Restaurants from API
    private func fetchRestaurantsFromAPI() async throws -> [Restaurant] {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode([Restaurant].self, from: data)
    }

    // Fetch Restaurant Detail from API
    private func fetchRestaurantDetailFromAPI(name: String) async throws -> Restaurant {
        guard var urlComponents = URLComponents(string: "\(baseURL)go_detail") else {
            throw URLError(.badURL)
        }

        // 쿼리 파라미터 추가
        urlComponents.queryItems = [
            URLQueryItem(name: "name", value: name)
        ]

        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase // JSON 키를 스네이크 케이스에서 카멜 케이스로 자동 변환
        let decodedResponse = try decoder.decode([String: [Restaurant]].self, from: data)

        guard let restaurant = decodedResponse["results"]?.first else {
            throw URLError(.cannotDecodeContentData)
        }
        return restaurant
    }

    // Fetch Images for a Restaurant
    private func fetchImages(restaurantName: String) async -> [UIImage]? {
        guard var urlComponents = URLComponents(string: imageBaseURL) else {
            print("Invalid image base URL")
            return nil
        }

        // 쿼리 파라미터 추가
        urlComponents.queryItems = [
            URLQueryItem(name: "restaurant_name", value: restaurantName)
        ]

        guard let url = urlComponents.url else {
            print("Invalid image URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to fetch images: Invalid server response")
                return nil
            }

            // Parse image names from API response
            let imageNames = try JSONDecoder().decode([String].self, from: data)

            // Download each image
            var images: [UIImage] = []
            for imageName in imageNames {
                if let image = await fetchImage(imageName: imageName) {
                    images.append(image)
                }
            }
            return images
        } catch {
            print("Failed to fetch images: \(error.localizedDescription)")
            return nil
        }
    }

    // Fetch a single image
    private func fetchImage(imageName: String) async -> UIImage? {
        guard let url = URL(string: "\(imageBaseURL)?file_key=\(imageName)") else {
            print("Invalid image URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return UIImage(data: data) // 이미지 변환
        } catch {
            print("Failed to fetch image: \(error.localizedDescription)")
            return nil
        }
    }
}
