//  ContentView.swift
//  SwoftUI-Weather
//
//  Created by Macbook on 14.10.2023.
//"cloud.sun.fill"

import SwiftUI
struct ContentView: View {
    
    @State private var isNight = false
    @State private var weatherData: [WeatherDayView] = []
    @State private var currentWeather: MainStatusWeatherView = MainStatusWeatherView(systemNameImg: "cloud.sun.fill", temp_c: 0)
func dayOfWeek(for index: Int? = nil) -> String {
        let days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        
        let startIndex = Calendar.current.component(.weekday, from: Date())
        let adjustedIndex = (startIndex + (index ?? 0)) % 7
        let dayIndex = adjustedIndex >= 0 ? adjustedIndex : adjustedIndex + 7
        
        return days[dayIndex]
    }
    
    
    var body: some View {
        ZStack {
            BackgraundView(isNight: $isNight)
            VStack {
                CityTextView(cityName: "Rivne, UA")
                MainStatusWeatherView(systemNameImg: currentWeather.systemNameImg,
                                      temp_c: currentWeather.temp_c)

                HStack(spacing: 20) {
                    ForEach(weatherData.prefix(5).indices, id: \.self) { dayIndex in
                        let dayString = dayOfWeek(for: dayIndex)  // Pass the actual dayIndex here

                        if dayIndex < weatherData.count {
                            weatherData[dayIndex].body
                        }
                    }

                }
                Spacer()

                Button {
                    isNight.toggle()
                } label: {
                    WeatherButton(title: "Change Day Time",
                                  textColor: .white,
                                  backgroundColor: .blue)
                }
                Spacer()
            }
        }
        .onAppear {
            fetchWeatherData()
        }
    }

    func fetchWeatherData() {
            Task {
                do {
                    let (current, forecast) = try await getTemp()
                    self.weatherData = forecast
                    self.currentWeather = current
                } catch APIError.invalidURL {
                    print("Invalid URL! Try again;)")
                } catch APIError.invalidResponse {
                    print("No response!")
                } catch APIError.invalidData {
                    print("Invalid data, try later...")
                } catch {
                    print("Unexpected error...")
                }
            }
        }
    }

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

func systemNameForTemperature(_ temperature: Double) -> String {
    switch temperature {
    case ..<0:
        return "cloud.snow.fill"
    case 0..<10:
        return "cloud.fill"
    case 10..<20:
        return "cloud.sun.fill"
    case 20..<30:
        return "sun.max.fill"
    default:
        return "sun.max.fill"
    }
}

func getTemp() async throws -> (current: MainStatusWeatherView, forecast: [WeatherDayView]) {
    let endpoint = "https://api.open-meteo.com/v1/forecast?latitude=50.6071&longitude=26.1416&current=temperature_2m&daily=temperature_2m_max&timezone=GMT"
    guard let url = URL(string: endpoint) else {
        throw APIError.invalidURL
    }
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw APIError.invalidResponse
    }
    do {
            let decoder = JSONDecoder()
            let weatherData = try decoder.decode(WeatherData.self, from: data)
            let currentTemperature = weatherData.current.temperature_2m
            let currentWeatherIcon = systemNameForTemperature(currentTemperature)

            let currentWeather = MainStatusWeatherView(
                systemNameImg: currentWeatherIcon,
                temp_c: Int(currentTemperature)
            )

        let forecastWeather = zip(weatherData.daily.time, weatherData.daily.temperature_2m_max)
            .map { WeatherDayView(date: $0, temp: $1, index: 0) }


            return (current: currentWeather, forecast: forecastWeather)

        } catch let decodingError {
            print("Error decoding JSON: \(decodingError)")
            throw APIError.invalidData
        }
    }



struct WeatherDayView: Identifiable {
    var id: String { date }
    
    var date: String
    var temp: Double
    var index: Int
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(dayOfWeek(for: index))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Image(systemName: systemNameForTemperature(temp))
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
            Text("\(Int(temp))°")
                .font(.system(size: 28, weight: .medium, design: .default))
                .foregroundColor(.white)
        }
    }
    
    
    func dayOfWeek(for index: Int) -> String {
        let days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        
        let todayIndex = Calendar.current.component(.weekday, from: Date())
        let adjustedIndex = (todayIndex + index) % 7
        let dayIndex = adjustedIndex >= 0 ? adjustedIndex : adjustedIndex + 7
        
        return days[dayIndex]
    }
}

struct BackgraundView: View {
    @Binding var isNight: Bool
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [isNight ? .black : .blue, isNight ? Color.gray : Color("lightblue")]),
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
        .edgesIgnoringSafeArea(.all)
    }
}
struct CityTextView: View{
    var cityName: String
    var body: some View{
        Text(cityName)
            .font(.system(size: 34, weight: .medium, design: .default))
            .foregroundColor(.white)
    }
}
struct MainStatusWeatherView: View {
    var systemNameImg: String
    var temp_c: Int
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: systemNameImg)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
            
            Text("\(temp_c)°")
                .font(.system(size: 70, weight: .medium, design: .default))
                .foregroundColor(.white)
        }
        .padding(.bottom, 40)
    }
}


struct WeatherData: Decodable {
    let current: CurrentData
    let daily: DailyData
}

struct CurrentData: Decodable {
    let temperature_2m: Double
}

struct DailyData: Decodable {
    let time: [String]
    let temperature_2m_max: [Double]
}



enum APIError : Error {
    case invalidURL
    case invalidResponse
    case invalidData
}
