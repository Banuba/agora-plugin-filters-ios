import UIKit

class EffectViewModel {
  let image: UIImage
  let effectName: String?
  var cancelEffectModel: Bool {
    return effectName == nil
  }
  
  init(image: UIImage, effectName: String?) {
    self.image = image
    self.effectName = effectName
  }
}

class BanubaEffectSelectorView: UIView  {
  
  @IBOutlet weak var carousel: iCarousel!
  
  var didSelectEffectViewModel: ((_ effectViewModel: EffectViewModel) -> Void)?
  var didSelectCloseEffectsView: ((_ sender: UIButton) -> Void)?
  
  var effectViewModels: [EffectViewModel] = [] {
    didSet {
      carousel.reloadData()
    }
  }
  
  var selectedEffectViewModel: EffectViewModel? {
    didSet {
      guard let index = effectViewModels.firstIndex(where: { $0 === selectedEffectViewModel }) else {
        return
      }
      
      carousel.scrollToItem(at: index, animated: false)
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setupView()
    sharedInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    setupView()
    sharedInit()
  }
  
  override func draw(_ rect: CGRect) {
    super.draw(rect)
    
    carousel.reloadData()
  }
  
  // Performs the initial setup.
  private func setupView() {
    let view = viewFromNibForClass()
    view.frame = bounds
    
    view.autoresizingMask = [
      UIView.AutoresizingMask.flexibleWidth,
      UIView.AutoresizingMask.flexibleHeight
    ]
    
    addSubview(view)
  }
  
  private func sharedInit() {
    carousel.type = .linear
    carousel.bounceDistance = 0.5
  }
  
  private func viewFromNibForClass() -> UIView {
    let bundle = Bundle(for: type(of: self))
    let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
    let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
    
    return view
  }
}

extension BanubaEffectSelectorView: iCarouselDataSource, iCarouselDelegate {
  func numberOfItems(in carousel: iCarousel) -> Int {
    return effectViewModels.count
  }
  
  func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
    let itemView = UIImageView(
      frame: CGRect(
        x: 0,
        y: 0,
        width: carousel.frame.height,
        height: carousel.frame.height
      )
    )
    itemView.image = effectViewModels[index].image
    itemView.contentMode = .scaleAspectFit
    
    itemView.layer.cornerRadius = itemView.frame.size.width / 2
    itemView.layer.masksToBounds = true
    
    return itemView
  }
  
  func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
    if (option == .spacing) {
      return value * 1.1
    }
    return value
  }
  
  func carouselDidEndDecelerating(_ carousel: iCarousel) {
    didSelectEffectViewModel?(effectViewModels[carousel.currentItemIndex])
  }
  
  func carouselDidEndDragging(_ carousel: iCarousel, willDecelerate decelerate: Bool) {
    if !decelerate {
      didSelectEffectViewModel?(effectViewModels[carousel.currentItemIndex])
    }
  }
  
  func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
    didSelectEffectViewModel?(effectViewModels[index])
  }
  
  func carouselItemWidth(_ carousel: iCarousel) -> CGFloat {
    let spacing: CGFloat = 15.0
    return carousel.frame.height + spacing
  }
}
