//
//  FindAll.swift
//  DummyJson
//
//  Created by make on 31.5.2023.
//
import Foundation
import Alamofire

class FindAll {
    static func findAllUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        AF.request("https://dummyjson.com/users").responseDecodable(of: [User].self) { response in
            switch response.result {
            case .success(let users):
                completion(.success(users))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
