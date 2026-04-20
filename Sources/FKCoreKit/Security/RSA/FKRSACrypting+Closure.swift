import Foundation
@preconcurrency import Security

extension FKRSACrypting {
  public func generateKeyPair(
    keySize: Int,
    tag: String,
    storeInKeychain: Bool,
    completion: @escaping @Sendable (Result<FKRSAKeyPair, FKSecurityError>) -> Void
  ) {
    Task {
      do { completion(.success(try await generateKeyPair(keySize: keySize, tag: tag, storeInKeychain: storeInKeychain))) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }

  public func encrypt(
    _ data: Data,
    publicKey: SecKey,
    algorithm: FKRSAEncryptionAlgorithm,
    completion: @escaping @Sendable (Result<Data, FKSecurityError>) -> Void
  ) {
    Task {
      do { completion(.success(try await encrypt(data, publicKey: publicKey, algorithm: algorithm))) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }

  public func decrypt(
    _ data: Data,
    privateKey: SecKey,
    algorithm: FKRSAEncryptionAlgorithm,
    completion: @escaping @Sendable (Result<Data, FKSecurityError>) -> Void
  ) {
    Task {
      do { completion(.success(try await decrypt(data, privateKey: privateKey, algorithm: algorithm))) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }

  public func sign(
    _ data: Data,
    privateKey: SecKey,
    algorithm: FKRSAKindOfSignature,
    completion: @escaping @Sendable (Result<Data, FKSecurityError>) -> Void
  ) {
    Task {
      do { completion(.success(try await sign(data, privateKey: privateKey, algorithm: algorithm))) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }

  public func verify(
    _ signature: Data,
    data: Data,
    publicKey: SecKey,
    algorithm: FKRSAKindOfSignature,
    completion: @escaping @Sendable (Result<Bool, FKSecurityError>) -> Void
  ) {
    Task {
      do { completion(.success(try await verify(signature, data: data, publicKey: publicKey, algorithm: algorithm))) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }
}

