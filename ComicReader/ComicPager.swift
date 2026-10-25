import SwiftUI
import UIKit

final class PageContentVC: UIViewController, UIScrollViewDelegate {
    let index: Int
    private let session: ComicSession
    private let scroll = UIScrollView()
    private let imageView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .large)

    init(index: Int, session: ComicSession) {
        self.index = index
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        scroll.delegate = self
        scroll.minimumZoomScale = 1
        scroll.maximumZoomScale = 4
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never

        imageView.contentMode = .scaleAspectFit
        scroll.addSubview(imageView)
        view.addSubview(scroll)

        spinner.color = .white
        spinner.startAnimating()
        view.addSubview(spinner)

        session.load(index) { [weak self] image in
            guard let self else { return }
            self.imageView.image = image
            self.spinner.stopAnimating()
        }
        session.prefetch(index + 1)
        session.prefetch(index - 1)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scroll.frame = view.bounds
        spinner.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        if scroll.zoomScale == 1 {
            imageView.frame = scroll.bounds
            scroll.contentSize = scroll.bounds.size
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
}

struct ComicPager: UIViewControllerRepresentable {
    let session: ComicSession
    @Binding var page: Int
    let animated: Bool
    let onToggleChrome: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: nil
        )
        pvc.isDoubleSided = false
        pvc.dataSource = context.coordinator
        pvc.delegate = context.coordinator
        pvc.view.backgroundColor = .black

        // Απενεργοποιούμε τα δικά του taps, χρησιμοποιούμε τα δικά μας (αριστερά/δεξιά/κέντρο).
        for g in pvc.gestureRecognizers where g is UITapGestureRecognizer {
            g.isEnabled = false
        }
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped(_:)))
        tap.delegate = context.coordinator
        pvc.view.addGestureRecognizer(tap)

        context.coordinator.pvc = pvc
        let start = min(max(page, 0), session.pageCount - 1)
        context.coordinator.shownPage = start
        pvc.setViewControllers([context.coordinator.makePage(start)], direction: .forward, animated: false)
        return pvc
    }

    func updateUIViewController(_ pvc: UIPageViewController, context: Context) {
        let c = context.coordinator
        c.parent = self

        // Στο mode χωρίς animation δεν επιτρέπουμε swipe-curl.
        for g in pvc.gestureRecognizers where g is UIPanGestureRecognizer {
            g.isEnabled = animated
        }

        if page != c.shownPage, page >= 0, page < session.pageCount {
            let direction: UIPageViewController.NavigationDirection = page > c.shownPage ? .forward : .reverse
            c.shownPage = page
            pvc.setViewControllers([c.makePage(page)], direction: direction, animated: false)
        }
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIGestureRecognizerDelegate {
        var parent: ComicPager
        weak var pvc: UIPageViewController?
        var shownPage = 0
        private var busy = false

        init(_ parent: ComicPager) {
            self.parent = parent
        }

        func makePage(_ index: Int) -> PageContentVC {
            PageContentVC(index: index, session: parent.session)
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let vc = viewController as? PageContentVC, vc.index > 0 else { return nil }
            return makePage(vc.index - 1)
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let vc = viewController as? PageContentVC, vc.index < parent.session.pageCount - 1 else { return nil }
            return makePage(vc.index + 1)
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController],
                                transitionCompleted completed: Bool) {
            guard completed, let vc = pageViewController.viewControllers?.first as? PageContentVC else { return }
            shownPage = vc.index
            parent.page = vc.index
        }

        @objc func tapped(_ g: UITapGestureRecognizer) {
            guard let view = g.view, view.bounds.width > 0 else { return }
            let x = g.location(in: view).x / view.bounds.width
            if x < 0.3 {
                go(-1)
            } else if x > 0.7 {
                go(1)
            } else {
                parent.onToggleChrome()
            }
        }

        private func go(_ delta: Int) {
            guard !busy, let pvc, let current = pvc.viewControllers?.first as? PageContentVC else { return }
            let target = current.index + delta
            guard target >= 0, target < parent.session.pageCount else { return }

            let animated = parent.animated
            busy = animated
            shownPage = target
            pvc.setViewControllers(
                [makePage(target)],
                direction: delta > 0 ? .forward : .reverse,
                animated: animated
            ) { [weak self] _ in
                self?.busy = false
            }
            parent.page = target
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
